//
// Copyright © 2020 Bunny Wong
// Created on 2020/2/11.
//

import UIKit

class ToolBarButtonView: UIView {

    enum ToolBarButtonState {
        case selected
        case normal
        case disabled
    }

    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var tickImageView: UIImageView!

    weak var delegate: ToolBarButtonViewDelegate?

    var state: ToolBarButtonState = .normal {
        didSet {
            updateAppearanceForState()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        clipsToBounds = false

        button.layer.cornerRadius = bounds.size.width / 2.0
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 3.0
        button.clipsToBounds = true

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        updateAppearanceForState()
    }

    func updateAppearanceForState() {
        switch state {
        case .selected:
            button.isEnabled = true
            tickImageView.isHidden = false
        case .normal:
            button.isEnabled = true
            tickImageView.isHidden = true
        case .disabled:
            button.isEnabled = false
            tickImageView.isHidden = true
        }
    }

    @objc func buttonTapped(_ sender: UIButton) {
        switch state {
        case .selected:
            state = .normal
        case .normal:
            state = .selected
        case .disabled:
            break
        }
        delegate?.toolBarButtonTapped(buttonView: self)
    }

}

@objc protocol ToolBarButtonViewDelegate: AnyObject {

    func toolBarButtonTapped(buttonView: ToolBarButtonView)

}
