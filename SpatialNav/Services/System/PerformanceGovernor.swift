//
//  PerformanceGovernor.swift
//  SpatialNav
//

import Foundation
import UIKit

/// Watches thermal state, Low Power Mode, and battery level, and publishes the
/// processing tier every expensive subsystem subscribes to. Polling (5 s) is
/// used alongside notifications because thermal state has no async sequence and
/// the arbiter's delayed upgrades need periodic re-evaluation anyway.
actor PerformanceGovernor: PerformanceGoverning {
    private let policy = TierPolicy()
    private var arbiter: TierArbiter
    private var tier: ProcessingTier = .full
    private var continuations: [UUID: AsyncStream<ProcessingTier>.Continuation] = [:]
    private var monitorTask: Task<Void, Never>?
    private let pollInterval: Duration

    init(upgradeDelay: TimeInterval = 30, pollInterval: Duration = .seconds(5)) {
        self.arbiter = TierArbiter(upgradeDelay: upgradeDelay)
        self.pollInterval = pollInterval
    }

    var currentTier: ProcessingTier {
        tier
    }

    func tiers() -> AsyncStream<ProcessingTier> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
            continuations[id] = continuation
            continuation.yield(tier)
        }
    }

    func start() {
        guard monitorTask == nil else { return }
        monitorTask = Task { [weak self] in
            await MainActor.run { UIDevice.current.isBatteryMonitoringEnabled = true }
            while !Task.isCancelled {
                await self?.evaluate()
                try? await Task.sleep(for: self?.pollInterval ?? .seconds(5))
            }
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    private func evaluate() async {
        let thermal = ThermalLevel(ProcessInfo.processInfo.thermalState)
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        let battery = await MainActor.run { UIDevice.current.batteryLevel }
        let target = policy.target(thermal: thermal, isLowPowerMode: lowPower, batteryLevel: battery)
        let applied = arbiter.ingest(target: target, at: CFAbsoluteTimeGetCurrent())
        guard applied != tier else { return }
        tier = applied
        for continuation in continuations.values {
            continuation.yield(applied)
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }
}

extension ThermalLevel {
    fileprivate nonisolated init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .serious
        }
    }
}
