//
//  NotificationManager.swift
//  Pulse
//
//  Handles all push notifications for the app
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    
    @Published var isAuthorized: Bool = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    // MARK: - Notification Identifiers
    
    private enum NotificationID {
        static let morningReminder = "pulse.morning.reminder"
        static let eveningReflection = "pulse.evening.reflection"
        static let projectDying = "pulse.project.dying"
        static let projectDead = "pulse.project.dead"
        static let streakAtRisk = "pulse.streak.risk"
        static let dailyThree = "pulse.daily.three"
    }
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Morning Reminder
    
    func scheduleMorningReminder(hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! ☀️"
        content.body = "Time to pick your Daily Three and set your focus for today."
        content.sound = .default
        content.categoryIdentifier = "DAILY_THREE"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.morningReminder,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling morning reminder: \(error)")
            }
        }
    }
    
    // MARK: - Evening Reflection
    
    func scheduleEveningReflection(hour: Int = 20, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Reflect 🌙"
        content.body = "How did your projects go today? Take a moment to log your progress."
        content.sound = .default
        content.categoryIdentifier = "REFLECTION"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.eveningReflection,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling evening reflection: \(error)")
            }
        }
    }
    
    // MARK: - Project Health Notifications
    
    func scheduleProjectDyingNotification(projectName: String, projectID: UUID, daysUntilDead: Int) {
        let content = UNMutableNotificationContent()
        content.title = "💔 \(projectName) is Dying"
        content.body = "This project hasn't been touched in a while. It will flatline in \(daysUntilDead) days."
        content.sound = .default
        content.userInfo = ["projectID": projectID.uuidString]
        content.categoryIdentifier = "PROJECT_DYING"
        
        // Trigger immediately or after a delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.projectDying).\(projectID.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleProjectDeadNotification(projectName: String, projectID: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "💀 \(projectName) has Flatlined"
        content.body = "It's been 30 days. Time to decide: revive, hibernate, or let it go?"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("flatline.wav"))
        content.userInfo = ["projectID": projectID.uuidString]
        content.categoryIdentifier = "PROJECT_DEAD"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.projectDead).\(projectID.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Streak Notifications
    
    func scheduleStreakAtRiskNotification(projectName: String, projectID: UUID, currentStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak at Risk!"
        content.body = "Your \(currentStreak)-day streak on \(projectName) will break tomorrow. Touch it today!"
        content.sound = .default
        content.userInfo = ["projectID": projectID.uuidString]
        content.categoryIdentifier = "STREAK_RISK"
        
        // Schedule for 6 PM if not touched today
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.streakAtRisk).\(projectID.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Daily Three Reminder
    
    func scheduleDailyThreeReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🎯 Daily Three Waiting"
        content.body = "You haven't picked your focus projects for today yet."
        content.sound = .default
        content.categoryIdentifier = "DAILY_THREE"
        
        // Schedule for 10 AM if not done
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyThree,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelProjectNotifications(projectID: UUID) {
        let identifiers = [
            "\(NotificationID.projectDying).\(projectID.uuidString)",
            "\(NotificationID.projectDead).\(projectID.uuidString)",
            "\(NotificationID.streakAtRisk).\(projectID.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Fetch Pending
    
    func fetchPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            Task { @MainActor in
                self.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - Register Categories
    
    func registerNotificationCategories() {
        // Daily Three category
        let touchAction = UNNotificationAction(
            identifier: "TOUCH_PROJECT",
            title: "Touch Project",
            options: .foreground
        )
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 1 hour",
            options: []
        )
        
        let dailyThreeCategory = UNNotificationCategory(
            identifier: "DAILY_THREE",
            actions: [touchAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Project dying category
        let reviveAction = UNNotificationAction(
            identifier: "REVIVE_PROJECT",
            title: "Revive Now",
            options: .foreground
        )
        let hibernateAction = UNNotificationAction(
            identifier: "HIBERNATE_PROJECT",
            title: "Hibernate",
            options: .destructive
        )
        
        let projectDyingCategory = UNNotificationCategory(
            identifier: "PROJECT_DYING",
            actions: [reviveAction, hibernateAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Streak risk category
        let streakRiskCategory = UNNotificationCategory(
            identifier: "STREAK_RISK",
            actions: [touchAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            dailyThreeCategory,
            projectDyingCategory,
            streakRiskCategory
        ])
    }
}
