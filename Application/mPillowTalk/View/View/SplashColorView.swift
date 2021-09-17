//
//  SplashColorView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/29.
//

import SwiftUI

struct SplashColorView: UIViewRepresentable {
    let config: SplashColor.Configuration

    @Binding var animated: Bool
    let view = SplashColor()

    func makeUIView(context _: Context) -> SplashColor {
        toggleAnimation()
        return view
    }

    func updateUIView(_: SplashColor, context _: Context) {
        toggleAnimation()
    }

    func toggleAnimation() {
        DispatchQueue.global().async {
            if self.animated {
                DispatchQueue.main.async {
                    self.view.animate()
                }
            } else {
                DispatchQueue.main.async {
                    self.view.stopAnimate()
                }
            }
        }
    }
}

struct SplashColorView_Previews: PreviewProvider {
    @State static var yes: Bool = true
    static var previews: some View {
        SplashColorView(config: .init(), animated: SplashColorView_Previews.$yes)
    }
}

class SplashColor: UIView {
    struct Configuration {
        let colors: [UIColor]
        let numsersOfColorDot: Int
        let effect: UIBlurEffect?
        public init(colors: [UIColor] = [#colorLiteral(red: 0.9586862922, green: 0.660125792, blue: 0.8447988033, alpha: 1), #colorLiteral(red: 0.8714533448, green: 0.723166883, blue: 0.9342088699, alpha: 1), #colorLiteral(red: 0.7458761334, green: 0.7851135731, blue: 0.9899476171, alpha: 1), #colorLiteral(red: 0.4398113191, green: 0.8953480721, blue: 0.9796616435, alpha: 1), #colorLiteral(red: 0.3484552801, green: 0.933657825, blue: 0.9058339596, alpha: 1), #colorLiteral(red: 0.5567936897, green: 0.9780793786, blue: 0.6893508434, alpha: 1), #colorLiteral(red: 0.8850132227, green: 0.9840424657, blue: 0.4586077332, alpha: 1)],
                    numsersOfColorDot: Int = 16,
                    effect: UIBlurEffect? = UIBlurEffect(style: .regular))
        {
            self.colors = colors
            self.numsersOfColorDot = numsersOfColorDot
            self.effect = effect
        }
    }

    private var config: Configuration = .init()
    private var colorViews = [UIView]()
    private var prevSize = CGSize()
    private var isAnimated = false
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    init(config: Configuration = .init()) {
        super.init(frame: CGRect())
        self.config = config
        initializeColorViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        debugPrint("SplashColors were not designed for coders")
        initializeColorViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if prevSize != frame.size {
            debugPrint("\(#file) \(#function) prevSize != frame.size")
            colorViews.forEach { view in
                view.layer.removeAllAnimations()
            }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               usingSpringWithDamping: 1,
                               initialSpringVelocity: 0.8,
                               options: .curveEaseInOut) {
                    self.recalculateDotFrames()
                } completion: { _ in
                }
            }
        }
    }

    func initializeColorViews() {
        clipsToBounds = true
        if let effect = config.effect {
            blurEffectView.effect = effect
        } else {
            blurEffectView.isHidden = true
        }
        colorViews.forEach { view in
            view.removeFromSuperview()
        }
        colorViews = []
        var copy = config.colors
        for _ in 0 ..< config.numsersOfColorDot {
            if copy.count < 1 {
                copy = config.colors
            }
            if copy.count < 1 {
                copy = [.black]
            }
            copy.shuffle()
            let view = UIView()
            view.backgroundColor = copy.removeFirst()
            view.alpha = CGFloat.random(in: 0.5 ... 0.8)
            addSubview(view)
            colorViews.append(view)
        }
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)
        recalculateDotFrames()
    }

    func recalculateDotFrames() {
        prevSize = frame.size
        let width = frame.width
        let height = frame.height
        colorViews.forEach { view in
            view.center = CGPoint(x: CGFloat.random(in: 0 ... width), y: CGFloat.random(in: 0 ... height))
            let suggestedWidth = CGFloat.random(in: (width * 0.2) ... (width * 0.8))
            let suggestedHeight = CGFloat.random(in: (height * 0.2) ... (height * 0.8))
            let decision = (suggestedWidth + suggestedHeight) / 2
            view.frame.size = CGSize(width: decision, height: decision)
            view.layer.cornerRadius = decision / 2
        }
    }

    func animate() {
        if isAnimated {
            return
        }
        isAnimated = true
        let width = frame.width
        let height = frame.height
        let suggestedWidth = CGFloat.random(in: (width * 0.2) ... (width * 0.8))
        let suggestedHeight = CGFloat.random(in: (height * 0.2) ... (height * 0.8))
        let decision = (suggestedWidth + suggestedHeight) / 2
        var speed = (decision / 50) * CGFloat.random(in: 0.6 ... 2.0)
        if speed < 1 {
            speed = 1
        }
        DispatchQueue.global().async { [weak self] in
            while self?.isAnimated ?? false {
                if let self = self {
                    self.switchNextAtomically(duration: Double(speed))
                }
            }
        }
    }

    func switchNextAtomically(duration: Double) {
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            UIView.animate(withDuration: TimeInterval(duration),
                           delay: 0,
                           options: .curveEaseInOut) {
                self.recalculateDotFrames()
            } completion: { _ in
                sem.signal()
            }
        }
        _ = sem.wait(timeout: .now() + Double(duration) + 0.1)
    }

    func stopAnimate() {
        if !isAnimated {
            return
        }
        isAnimated = false
    }
}
