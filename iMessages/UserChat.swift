//
//  User.swift
//  iMessages
//
//  Created by Sirin on 29/01/2018.
//  Copyright © 2018 Sirin. All rights reserved.
//

import Foundation

class UserChat: NSObject {
    
    var name: String
    var email: String
    
    init(name: String, email: String){
        self.name = name
        self.email = email
    }
    
}
