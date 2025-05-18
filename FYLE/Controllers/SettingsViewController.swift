//
//  SettingsViewController.swift
//  FYLE
//
//  Created by Sana Sreeraj on 10/03/25.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var notificationToggle: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load notification setting from UserDefaults
        notificationToggle.isOn = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    @IBAction func notificationToggleChanged(_ sender: UISwitch) {
        // Save notification setting to UserDefaults
        UserDefaults.standard.set(sender.isOn, forKey: "notificationsEnabled")
        
        if !sender.isOn {
            // Cancel all pending notifications if disabled
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}
