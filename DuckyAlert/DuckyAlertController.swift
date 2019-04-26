//
//  SimplyAlertController.swift
//  SimplyMacros
//
//  Created by BryanA Caragay on 1/13/19.
//  Copyright © 2019 Scrappy Technologies. All rights reserved.
//

import UIKit

struct AlertStyle {
    var buttonBackgroundColor: UIColor = UIColor.white
    var buttonPositiveTextColor: UIColor = UIColor.green
    var buttonNegativeTextColor: UIColor = UIColor.red
    var buttonDefaultTextColor: UIColor = UIColor.gray
    var modalBackgroundColor: UIColor = UIColor.white

    init(buttonBackgroundColor: UIColor = UIColor.white, buttonPositiveTextColor: UIColor = UIColor.green, buttonNegativeTextColor: UIColor = UIColor.red, buttonDefaultTextColor: UIColor = UIColor.darkGray, modalBackgroundColor: UIColor = UIColor.white) {
        self.buttonBackgroundColor      = buttonBackgroundColor
        self.buttonPositiveTextColor    = buttonPositiveTextColor
        self.buttonNegativeTextColor    = buttonNegativeTextColor
        self.buttonDefaultTextColor     = buttonDefaultTextColor
        self.modalBackgroundColor       = modalBackgroundColor
    }
}

struct AlertAction {
    public enum Style {
        case negative
        case positive
        case destructive
    }

    var title: String

    var style: Style

    var handler: (() -> Void)?

    public init(title: String, style: Style, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

public class SimplyAlertController: UIViewController {
    // MARK: - Properties

    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
//        label.font = Font.large(weight: .semibold)
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.white
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
//        label.font = Font.medium(weight: .regular)
        label.textColor = UIColor.darkGray
        label.backgroundColor = UIColor.white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    private let alertStackView = UIStackView()
    private let actionStackView = UIStackView()
    private var actions = [AlertAction]()
    private var style = AlertStyle() {
        didSet {
            container.backgroundColor = style.modalBackgroundColor
        }
    }

    var customView: UIView?
    private var backgroundAction: (() -> Void)?

    // MARK: - Initializers

    init(image: UIImage?, imageTintColor: UIColor? = nil, title: String, message: String) {
        super.init(nibName: nil, bundle: nil)

        if imageTintColor != nil {
            imageView.image = image?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = imageTintColor
        } else {
            imageView.image = image
        }

        titleLabel.text = title
        messageLabel.text = message

        definePresentationStyle()
        addSubviews()
    }

    init(title: String, message: String, style: AlertStyle = AlertStyle()) {
        super.init(nibName: nil, bundle: nil)

        titleLabel.text = title
        messageLabel.text = message
        self.style = style

        definePresentationStyle()
        addSubviews()
    }

    init(image: UIImage?, imageTintColor: UIColor? = nil, title: String, attributedMessage: NSAttributedString) {
        super.init(nibName: nil, bundle: nil)

        if imageTintColor != nil {
            imageView.image = image?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = imageTintColor
        } else {
            imageView.image = image
        }
        titleLabel.text = title
        messageLabel.attributedText = attributedMessage
        definePresentationStyle()
        addSubviews()
    }

    init(customView: UIView, height: CGFloat) {
        super.init(nibName: nil, bundle: nil)
        self.customView = customView
        alertStackView.addArrangedSubview(customView)
        definePresentationStyle()
        setupContainer(height: height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addBackgroundNotification()
        actionStackView.axis = actions.count > 2 ? .vertical : .horizontal

        for view in actionStackView.arrangedSubviews {
            actionStackView.removeArrangedSubview(view)
        }

        for button in buildButtons(with: actions) {
            actionStackView.addArrangedSubview(button)
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(container)

        alertStackView.axis = .vertical
        alertStackView.spacing = 10

        actionStackView.distribution = .fillEqually

        container.addSubview(alertStackView)
        container.addSubview(actionStackView)

        NSLayoutConstraint.activate([
            alertStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            alertStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            alertStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 15),
        ])

        setupContainer()

        NSLayoutConstraint.activate([
            actionStackView.topAnchor.constraint(equalTo: alertStackView.bottomAnchor, constant: 20),
            actionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if imageView.image == nil {
            imageView.isHidden = true
        }
    }

    // MARK: - Methods

    private func setupContainer(height: CGFloat? = nil) {
        container.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)

        if let height = height {
            container.heightAnchor.constraint(equalToConstant: height)
        } else {
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
            container.heightAnchor.constraint(lessThanOrEqualToConstant: 400)
        }
    }

    private func addSubviews() {
        alertStackView.addArrangedSubview(imageView)
        alertStackView.addArrangedSubview(titleLabel)
        alertStackView.addArrangedSubview(messageLabel)
    }

    /// Sets the action to be performed when the app is backgrounded with the modal open.
    func performActionOnBackground(action: @escaping () -> Void) {
        backgroundAction = action
    }

    /// Adds an action to the modal
    func addAction(_ action: AlertAction) {
        if isBeingPresented { return }
        actions.append(action)
    }

    /// Notify the modal the app has moved to the background, to conform to Apple HIG.
    @objc
    func appMovedToBackground() {
        removeBackgroundNotification()
        backgroundAction?()
        dismiss(animated: true, completion: nil)
    }

    /// Triggered when a button is tapped. Dismisses the modal and performs that buttons' action.
    @objc
    func onButtonTapped(_ sender: AlertButton) {
        removeBackgroundNotification()
        dismiss(animated: true, completion: nil)
        sender.performAction()
    }

    private func buildButtons(with actions: [AlertAction]) -> [UIButton] {
        var buttons = [UIButton]()

        for (index, action) in actions.enumerated() {

            let defaultHandler = { [weak self] in
                guard let `self` = self else { return }
                self.dismiss(animated: true, completion: nil)
            }

            let actionButton = AlertButton(handler: action.handler ?? defaultHandler, style: style)
            actionButton.setTitle(action.title, style: action.style)
            actionButton.heightAnchor.constraint(equalToConstant: 60)
            actionButton.addSeparator(position: .top)
            actionButton.addTarget(self, action: #selector(onButtonTapped(_:)), for: .touchUpInside)
            if actions.count < 3, index > 0 {
                actionButton.addSeparator(position: .left)
            }

            buttons.append(actionButton)
        }

        return buttons
    }

    /// Sets the presentation style of the modal.
    private func definePresentationStyle() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }

    /// Add the background notification listener.
    private func addBackgroundNotification() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }

    /// Remove the background notification listener.
    private func removeBackgroundNotification() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
}

class AlertButton: UIButton {

    // MARK: - Properties

    enum SeparatorPosition {
        case left
        case top
    }

    private (set) var handler: () -> Void
    private var style: AlertStyle

    // MARK: - Initializers

    required init(handler: @escaping () -> Void, style: AlertStyle) {
        self.handler = handler
        self.style = style
        super.init(frame: .zero)
        backgroundColor = self.style.buttonBackgroundColor

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    @objc
    func performAction() {
        handler()
    }

    func setTitle(_ title: String, style: AlertAction.Style) {
        var fontColor: UIColor
        switch style {
        case .negative:     fontColor = self.style.buttonDefaultTextColor
        case .destructive:  fontColor = self.style.buttonNegativeTextColor
        case .positive:     fontColor = self.style.buttonPositiveTextColor
        }

        setAttributedTitle(NSAttributedString(string: title, attributes: [.foregroundColor: fontColor]), for: .normal)
        setAttributedTitle(NSAttributedString(string: title, attributes: [.foregroundColor: fontColor.withAlphaComponent(0.5)]), for: .highlighted)
    }

    func addSeparator(position: SeparatorPosition) {
        let separator = UIView()
        separator.backgroundColor = UIColor.lightGray
        addSubview(separator)

        switch position {
        case .left:
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.bottomAnchor.constraint(equalTo: bottomAnchor),
                separator.topAnchor.constraint(equalTo: topAnchor),
                separator.widthAnchor.constraint(equalToConstant: 1)
            ])
        case .top:
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor),
                separator.topAnchor.constraint(equalTo: topAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
    }
}
