//
//  StepperButtonRow.swift
//
// Created by David HM Spector (ds@realm.io)
//
// Based on StepperRow.swift
//  Created by Andrew Holt on 3/4/16.
//  Copyright © 2016 Xmartlabs. All rights reserved.
//

import UIKit
import Eureka

// MARK: StepperButtonCell

func isNegative(n: Double) -> Bool { return n < 0 }
func isPositive(n: Double) -> Bool { return n > 0 }

open class StepperButtonCell : Cell<Double>, CellType {
    
    public typealias Value = Double
    
    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.button = UIButton()
        self.button.translatesAutoresizingMaskIntoConstraints = false

        self.stepper = UIStepper()
        self.stepper.translatesAutoresizingMaskIntoConstraints = false
        self.stepper.minimumValue = -500

        self.valueLabel = UILabel()
        self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.valueLabel.numberOfLines = 1

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        height = { BaseRow.estimatedRowHeight }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var stepper: UIStepper
    public var button: UIButton
    public var valueLabel: UILabel
    
    open override func setup() {
        super.setup()
        selectionStyle = .none
        
        addSubview(stepper)
        addSubview(button)
        addSubview(valueLabel)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v]-(20)-[s]-[b]-|", options: .alignAllCenterY, metrics: nil, views: ["s": stepper, "v": valueLabel, "b": button]))
        addConstraint(NSLayoutConstraint(item: stepper, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: stepper, attribute: .centerY, multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: valueLabel, attribute: .centerY, relatedBy: .equal, toItem: stepper, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        stepper.addTarget(self, action: #selector(StepperButtonCell.valueChanged), for: .valueChanged)
        button.addTarget(self, action: #selector(StepperButtonCell.valueChanged), for: .touchUpInside)
        valueLabel.textColor = stepper.tintColor
        button.tintColor = stepper.tintColor
        button.setTitle(" Add  ", for: .normal)
        button.setTitleColor(stepper.tintColor, for: .normal)
        button.setTitleColor(.gray, for: .disabled)

    }
    
    deinit {
        stepper.removeTarget(self, action: nil, for: .allEvents)
        button.removeTarget(self, action: nil, for: .allEvents)
    }
    
    open override func update() {
        super.update()
        stepper.isEnabled = !row.isDisabled
        stepper.value = row.value ?? 0
        stepper.alpha = row.isDisabled ? 0.3 : 1.0
        valueLabel.alpha = row.isDisabled ? 0.3 : 1.0
        valueLabel.text = row.displayValueFor?(row.value)
        detailTextLabel?.text = nil
        
        if stepper.value > 0 {
            button.isEnabled = true
            button.setTitle(" Add  ", for: .normal)
        } else if stepper.value == 0 {
            button.isEnabled = false
        } else if stepper.value < 0 {
            button.isEnabled = true
            button.setTitle("Remove", for: .normal)
        }
    }
    
    
    func valueChanged() {
        row.value = stepper.value
        row.updateCell()
    }
}

// MARK: StepperButtonRow

open class _StepperButtonRow: Row<StepperButtonCell> {
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { value in
                                guard let value = value else { return nil }
                                return DecimalFormatter().string(from: NSNumber(value: value)) }
    }
}


/// Double row that has a UIStepper + UIButton as accessoryType
public final class StepperButtonRow: _StepperButtonRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
