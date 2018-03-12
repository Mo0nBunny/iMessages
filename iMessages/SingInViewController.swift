//
//  SingInViewController.swift
//  iMessages
//
//  Created by Sirin on 29/01/2018.
//  Copyright © 2018 Sirin. All rights reserved.
//

import UIKit
import Firebase
import GradientLoadingBar
import Flurry_iOS_SDK

class SingInViewController: UIViewController, UIAlertViewDelegate {
    
    let gradientLoadingBar = GradientLoadingBar()
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var singInButton: UIButton!
    
    @IBAction func singInTapped(_ sender: Any) {
        gradientLoadingBar.show()
        guard let email = emailField.text, let password = passwordField.text, email.count > 0, password.count > 0 else {
//            Alert().showAlert(message: "Enter an email and a password.")
            showAlert(message: NSLocalizedString("001_error_enter_email_pass", comment: ""))
            
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let error = error {
                if error._code == AuthErrorCode.userNotFound.rawValue {
//                    Alert().showAlert(message: "There are no users with the specified account.")
                    self.showAlert(message: NSLocalizedString("002_error_no_user", comment: ""))
                } else if error._code == AuthErrorCode.wrongPassword.rawValue {
//                    Alert().showAlert(message: "Incorrect username or password.")
                    self.showAlert(message: NSLocalizedString("003_error_incorrect_user_pass", comment: ""))
                } else {
//                    Alert().showAlert(message: "Error: \(error.localizedDescription)")
                    self.showAlert(message: "\(NSLocalizedString("003_error_incorrect_user_pass", comment: ""))\(error.localizedDescription)")
                }
                print(error.localizedDescription)
                return
            }
            
            if let user = user {
                Flurry.logEvent("TimeInApp", withParameters: ["email": email], timed: true)
                AuthenticationManager.sharedInstance.didLogIn(user: user)
                self.performSegue(withIdentifier: "ShowChatsFromSingIn", sender: nil)
            }
        }
        gradientLoadingBar.hide()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        singInButton.layer.cornerRadius = 6.0
        singInButton.clipsToBounds = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        emailField.text = ""
        passwordField.text = ""
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "iMessages", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
