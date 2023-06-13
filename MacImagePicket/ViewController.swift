//
//  ViewController.swift
//  MTest
//
//  Created by Howard-Zjun on 2023/6/12.
//

import Cocoa

class ViewController: NSViewController {
    
    /// 框选大小
    var alphaRect: NSRect {
        .init(x: (view.frame.width - 300) * 0.5, y: (view.frame.height - 300) * 0.5, width: 300, height: 300)
    }
    
    /// 背景图片大小
    var imgSize: CGSize {
        if image.size.width < image.size.height {
            let width = alphaRect.width + 100
            let height = width / image.size.width * image.size.height
            return .init(width: width, height: height)
        } else {
            let height = alphaRect.height + 100
            let width = height / image.size.height * image.size.width
            return .init(width: width, height: height)
        }
    }
    
    let image: NSImage = .init(named: "a")!
    
    var lastPoint: CGPoint?
    
    lazy var imageView: NSImageView = {
        let imageView = NSImageView(frame: .init(x: (view.frame.width - imgSize.width) * 0.5, y: (view.frame.height - imgSize.height) * 0.5, width: imgSize.width, height: imgSize.height))
        imageView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }()
    
    lazy var alphaView: AlphaView = {
        let alphaView = AlphaView(frame: alphaRect)
        alphaView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        alphaView.addGestureRecognizer({
            NSPanGestureRecognizer(target: self, action: #selector(panImageGesture(_:)))
        }())
        return alphaView
    }()
    
    lazy var cutBtn: NSButton = {
        let cutBtn = NSButton(frame: .init(x: view.frame.width - 100, y: 0, width: 100, height: 50))
        cutBtn.wantsLayer = true
        cutBtn.autoresizingMask = [.maxXMargin, .minXMargin]
        cutBtn.title = "剪切"
        cutBtn.target = self
        cutBtn.action = #selector(touchCutBtn)
        return cutBtn
    }()
    
    // MARK: - life
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = .black
        view.addSubview(imageView)
        view.addSubview(alphaView)
        view.addSubview(cutBtn)
    }
    
    // MARK: - target
    @objc func panImageGesture(_ sender: NSPanGestureRecognizer) {
        let location = sender.location(in: alphaView)
        if sender.state == .began {
            lastPoint = location
        } else if sender.state == .changed {
            guard let lastPoint = lastPoint else {
                return
            }
            let offSetX = location.x - lastPoint.x, offSetY = location.y - lastPoint.y
            var minX = imageView.frame.minX + offSetX, minY = imageView.frame.minY + offSetY
            if minX > alphaView.frame.minX { // 左边进入范围内
                minX = alphaView.frame.minX
            } else if minX + imageView.frame.width < alphaView.frame.maxX { // 右边进入范围内
                minX = alphaView.frame.maxX - imageView.frame.width
            }
            
            if minY > alphaView.frame.minY { // 下边进入范围内
                minY = alphaView.frame.minY
            } else if minY + imageView.frame.height < alphaView.frame.maxY { // 上边进入范围内
                minY = alphaView.frame.maxY - imageView.frame.height
            }
            imageView.setFrameOrigin(.init(x: minX, y: minY))
            self.lastPoint = location
        } else {
            lastPoint = nil
        }
    }
    
    @objc func touchCutBtn() {
        cutImage()
    }
    
    // MARK: - 原子方法
    func cutImage() -> NSImage {
        let targetSize = CGSize(width: 300, height: 300)
        let minX = (alphaView.frame.minX - imageView.frame.minX) / imageView.frame.width * image.size.width
        let minY = (alphaView.frame.minY - imageView.frame.minY) / imageView.frame.height * image.size.height
        let width = alphaView.frame.width / imageView.frame.width * image.size.width
        let height = alphaView.frame.height / imageView.frame.height * image.size.height
        weak var weakSelf = self
        let ret = NSImage(size: targetSize, flipped: false) { rect in
            weakSelf?.image.draw(in: .init(origin: .zero, size: targetSize), from: .init(x: minX, y: minY, width: width, height: height), operation: .sourceOver, fraction: 1)
            return true
        }
        return ret
    }
}

extension ViewController {
    
    class AlphaView: NSView {
        
        override func draw(_ dirtyRect: NSRect) {
            let rectPath = NSBezierPath(rect: dirtyRect)
            rectPath.lineWidth = 2.0
            
            let holeRect = NSMakeRect(30 * dirtyRect.width / 300, 30 * dirtyRect.height / 300, dirtyRect.width - 60 * dirtyRect.width / 300, dirtyRect.height - 60 * dirtyRect.height / 300)
            let holePath = NSBezierPath(ovalIn: holeRect)
            
            rectPath.append(holePath)
            rectPath.windingRule = .evenOdd
            
            NSColor(white: 1, alpha: 0.3).setFill()
            rectPath.fill()
        }
    }
}

