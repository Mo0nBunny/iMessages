//
//  SingUpViewController.swift
//  iMessages
//
//  Created by Sirin on 29/01/2018.
//  Copyright © 2018 Sirin. All rights reserved.
//

import UIKit
import Firebase
import GradientLoadingBar
import Flurry_iOS_SDK

class SingUpViewController: UIViewController {
    let gradientLoadingBar = GradientLoadingBar()
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var singUpButton: UIButton!
    
    @IBAction func singUpTapped(_ sender: Any) {
        gradientLoadingBar.show()
        guard let name = nameTextField.text,
            let email = emailTextField.text,
            let password = passwordTextField.text,
            name.count > 0,
            email.count > 0,
            password.count > 0
            else {
//                Alert().showAlert(message: "Enter a name, an email and a password.")
                 showAlert(message: NSLocalizedString("005_error_enter_name_email_pass", comment: ""))
                return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                if error._code == AuthErrorCode.invalidEmail.rawValue {
//                    Alert().showAlert(message: "Enter a valid email.")
                     self.showAlert(message: NSLocalizedString("006_error_invalid_email", comment: ""))
                } else if error._code == AuthErrorCode.emailAlreadyInUse.rawValue {
//                    Alert().showAlert(message: "Email already in use.")
                    self.showAlert(message: NSLocalizedString("007_error_email_in_use", comment: ""))
                } else {
//                    Alert().showAlert(message: "Error: \(error.localizedDescription)")
                     self.showAlert(message: "\(NSLocalizedString("003_error_incorrect_user_pass", comment: ""))\(error.localizedDescription)")
                }
                print(error.localizedDescription)
                return
            }
            
            if let user = user {
                self.setUserName(user: user, name: name)
                let ref = Database.database().reference()
                let usersReference = ref.child("users").child(user.uid)
                let values = ["name": name, "email": email] as [String : Any]
                usersReference.updateChildValues(values, withCompletionBlock: {
                    (error, reff) in
                    if error != nil {
                        print(error ?? "no error")
                        return
                    }
                    print("User Saved")
                    Flurry.logEvent("NewUser", withParameters: ["name": name, "email": email])
                })
            }
        }
        gradientLoadingBar.hide()
    }
    
    func setUserName(user: User, name: String) {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        
        changeRequest.commitChanges(){ (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            AuthenticationManager.sharedInstance.didLogIn(user: user)
            Flurry.logEvent("TimeInApp", withParameters: ["email": user.email!], timed: true)
            self.performSegue(withIdentifier: "ShowChatsFromSingUp", sender: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        singUpButton.layer.cornerRadius = 6.0
        singUpButton.clipsToBounds = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "iMessages", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
