/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

internal class OCKGraphLegendView: UIStackView {
    private enum Constants {
        static let iconCornerRadius: CGFloat = 4.0
        static let iconPadding: CGFloat = 6.0
        static let keySpacing: CGFloat = 10.0
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        axis = .horizontal
        distribution = .fillEqually
        spacing = Constants.keySpacing
    }

    internal func setDataSeries(_ dataSeries: [OCKDataSeries]) {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        dataSeries.map(makeKey).forEach(addArrangedSubview)
    }

    private func makeKey(for series: OCKDataSeries) -> UIView {
        let icon = makeIcon(startColor: series.gradientStartColor ?? tintColor, endColor: series.gradientEndColor ?? tintColor)
        let label = makeLabel(title: series.title, color: series.gradientStartColor ?? tintColor)
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = Constants.iconPadding
        return stack
    }

    private func makeLabel(title: String, color: UIColor) -> UIView {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = color
        label.text = "\(title)"
        label.clipsToBounds = true
        return label
    }

    private func makeIcon(startColor: UIColor, endColor: UIColor) -> UIView {
        let icon = OCKGradientView()
        icon.startColor = startColor
        icon.endColor = endColor
        icon.clipsToBounds = true
        icon.layer.cornerRadius = Constants.iconCornerRadius
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.heightAnchor.constraint(equalTo: icon.widthAnchor).isActive = true
        return icon
    }
}

private class OCKGradientView: UIView {
    var startColor: UIColor = .red {
        didSet { gradient.colors = [startColor.cgColor, endColor.cgColor] }
    }

    var endColor: UIColor = .blue {
        didSet { gradient.colors = [startColor.cgColor, endColor.cgColor] }
    }

    private var gradient: CAGradientLayer {
        
        return layer as! CAGradientLayer
        
    }

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    init() {
        super.init(frame: .zero)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.endPoint = CGPoint(x: 0.5, y: 0)
    }
}
