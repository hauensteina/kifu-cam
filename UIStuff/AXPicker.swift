//
// AXPicker.swift
//
// Created by Andreas Hauenstein on 2020-02-08.
//

// A utility class to add a pickerview to a textfield

import UIKit

//=====================================================================================
@objc public class AXPicker: NSObject, UIPickerViewDelegate, UIPickerViewDataSource
{
    var vc:UIViewController?
    var tf:UITextField?
    var choices:[String]?
    var onCancel: ( ()->() )?
    var onDone: ( ()->() )?
    let picker = UIPickerView()
    var choice:String = ""
    
    //--------------------------------------------------------------------------
    @objc public override init() {
        super.init();
    }
    
    //-----------------------------------------------------------------------------
    @objc public init( VC vc:UIViewController, tf:UITextField, choices:[String]) {
        self.vc = vc
        self.tf = tf
        self.choices = choices
        self.onCancel = { () in }
        self.onDone = { () in }
        super.init()
        picker.delegate = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem( title: "Done", style: UIBarButtonItem.Style.plain,
                                          target: self, action: #selector(done))
        let spaceButton = UIBarButtonItem( barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                           target: nil, action: nil)
        let cancelButton = UIBarButtonItem( title: "Cancel", style: UIBarButtonItem.Style.plain,
                                            target: self, action: #selector(cancel))
        toolbar.setItems( [doneButton,spaceButton,cancelButton], animated: false)
        tf.inputAccessoryView = toolbar
        tf.inputView = picker
        tf.textColor = tf.tintColor
        
        //picker.dataSource = self
    } // init()
    
    //---------------------
    @objc func cancel() {
        self.vc!.view.endEditing(true)
    } // cancel()
    
    //-------------------
    @objc func done() {
        self.tf?.text = self.choice 
        self.vc!.view.endEditing(true)
    } // done()
    
    // UIPickerView Delegation
    //============================
    public func numberOfComponents( in pickerView: UIPickerView) -> Int { return 1 }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.choices!.count
    }
    public func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return choices![row]
    }
    public func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.choice = choices![row]
    }
} // class PXPicker
