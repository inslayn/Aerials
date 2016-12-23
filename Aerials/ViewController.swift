//
//  ViewController.swift
//  Aerials
//
//  Created by Nick McVroom-Amoakohene on 17/03/2016.
//  Copyright © 2016 inslayn in your membrane, ltd. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    let _baseUrl: String = "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos"
    
    var _moviePlayer:AVPlayer!
    var _moviePlayer2:AVPlayer!
    
    var _gestureView: UIView!
    let _playerViewController = AVPlayerViewController()
    
    var _progress: UIProgressView!
    
    var _locationText : UILabel!
    var _timeText : UILabel!
    var _dateText : UILabel!
    
    let _dateFormatter:NSDateFormatter = NSDateFormatter()
    
    var _allAssets: Array<AnyObject> = Array()
    var _assets: Array<(url: String, timeOfDay: String, place: String)> = Array()
    
    var _nextItem: AVPlayerItem!
    
    var _url: String = "", _timeofday: String = "", _place: String = ""
    
    override func viewWillAppear(animated: Bool) {
        print("will appear")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        getJSON()
        shuffleVideos()
        setupPlayer()
        setupProgress()
        setupGestures()
        setupOSD()
        startClock()
        
        start()
        
        // TODO: filter results betwixt day and night
        // TODO: choose day or night videos based on time of day
        // TODO: cache videos
        // TODO: have icons for day and night
        // TODO: choose a better clock and font display
        // TODO: choose favourite videos by tapping
        // TODO: only play favourite videos
        
    }
    
    func getJSON() -> Void {
        let jsonData: NSData = NSData(contentsOfURL: NSURL(string: "\(_baseUrl)/entries.json")!)!
        
        do {
            let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
            _allAssets = json as! Array<AnyObject>
            
            processAssets()
        }
        catch {
            print(error)
        }
    }
    
    func processAssets() -> Void {
        for var i: Int = 0, ni: Int = _allAssets.count; i < ni; i++ {
            let allAssets = _allAssets[i] as! Dictionary<String, AnyObject>
            let assets = allAssets["assets"] as! Array<AnyObject>
            
            for var j: Int = 0, nj: Int = assets.count; j < nj; j++ {
                let asset: Dictionary<String, AnyObject> = assets[j] as! Dictionary<String, AnyObject>
                
                _assets.append((asset["url"] as! String, asset["timeOfDay"] as! String, asset["accessibilityLabel"] as! String))
            }
        }
    }
    
    func setupPlayer() -> Void {
        _moviePlayer = AVPlayer()
        
        _moviePlayer.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
        
        _playerViewController.player = _moviePlayer
        _playerViewController.view.frame = view.frame
        
        _playerViewController.showsPlaybackControls = false
        _playerViewController.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.view.addSubview(_playerViewController.view)
        self.addChildViewController(_playerViewController)
    }
    
    func setupProgress() -> Void {
        _progress = UIProgressView(progressViewStyle: .Bar)
        _progress.frame.size.width = view.frame.width
        _progress.frame.origin = CGPointMake(0, view.frame.height - _progress.frame.height)
        _progress.progressTintColor = UIColor.whiteColor()
        _progress.hidden = true
        
        _playerViewController.view.addSubview(_progress)
    }
    
    func setupGestures() -> Void {
        _gestureView = UIView(frame: view.frame)
        _gestureView.backgroundColor = UIColor.clearColor()
        _playerViewController.view.addSubview(_gestureView)
        
        let rightSwipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "onRightSwipe:")
        rightSwipe.direction = .Right
        _gestureView.addGestureRecognizer(rightSwipe)
        
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "onSingleTap:")
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        _gestureView.addGestureRecognizer(singleTap)
        
        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "onDoubleTap:")
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        _gestureView.addGestureRecognizer(doubleTap)
        
        singleTap.requireGestureRecognizerToFail(doubleTap)
    }
    
    func onDoubleTap(recognizer: UIGestureRecognizer) {
        _locationText.hidden = !_locationText.hidden
        _dateText.hidden = !_dateText.hidden
        _timeText.hidden = !_timeText.hidden
    }
    
    func onSingleTap(recognizer: UIGestureRecognizer) {
        _progress.hidden = !_progress.hidden
    }
    
    func onRightSwipe(recognizer: UIGestureRecognizer) {
        start()
    }
    
    func setupOSD() -> Void {
        _dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
        
        _locationText = UILabel(frame: CGRectMake(5, 0, 200, 15))
        _dateText = UILabel(frame: CGRectMake(5, 10, 200, 15))
        _timeText = UILabel(frame: CGRectMake(5, 20, 200, 15))
        
        _locationText.font = UIFont(name: "Menlo", size: 8)
        _dateText.font = UIFont(name: "Menlo", size: 8)
        _timeText.font = UIFont(name: "Menlo", size: 8)
        
        _locationText.textColor = UIColor.whiteColor()
        _dateText.textColor = UIColor.whiteColor()
        _timeText.textColor = UIColor.whiteColor()
        
        _locationText.layer.shadowColor = UIColor.blackColor().CGColor
        _dateText.layer.shadowColor = UIColor.blackColor().CGColor
        _timeText.layer.shadowColor = UIColor.blackColor().CGColor
        
        _locationText.layer.shadowOpacity = 1
        _dateText.layer.shadowOpacity = 1
        _timeText.layer.shadowOpacity = 1
        
        _locationText.layer.shadowRadius = 0
        _dateText.layer.shadowRadius = 0
        _timeText.layer.shadowRadius = 0
        
        _locationText.layer.shadowOffset = CGSizeMake(1, 1)
        _dateText.layer.shadowOffset = CGSizeMake(1, 1)
        _timeText.layer.shadowOffset = CGSizeMake(1, 1)
        
        _gestureView.addSubview(_locationText)
        _gestureView.addSubview(_dateText)
        _gestureView.addSubview(_timeText)
    }
    
    func startClock() -> Void {
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "didProgress:", userInfo: nil, repeats: true)
    }
    
    func timerDidFire(timer: NSTimer) {
        _dateFormatter.dateFormat = "HH:mm:ss zzzz"
        
        let currentTime = _dateFormatter.stringFromDate(NSDate())
        
        if _timeText.text != currentTime {
            _timeText.text = currentTime
        }
        
        _dateFormatter.dateFormat = "EEEE, MMMM dd, yyyy"
        
        let currentDate = _dateFormatter.stringFromDate(NSDate())
        
        if _dateText.text != currentDate {
            _dateText.text = currentDate
        }
    }
    
    func didProgress(timer: NSTimer) {
        let elapsed = _moviePlayer.currentItem?.currentTime()
        let duration = _moviePlayer.currentItem?.duration
        
        if duration != nil && CMTimeGetSeconds(duration!) > 0 {
            _progress.progress = Float(CMTimeGetSeconds(elapsed!) / CMTimeGetSeconds(duration!))
        }
        
        if elapsed != nil && duration != nil && CMTimeGetSeconds(elapsed!) >= CMTimeGetSeconds(duration!) {
            start()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if object === _moviePlayer && keyPath == "status" {
            if _moviePlayer.status == .ReadyToPlay {
                _moviePlayer.play()
            }
        }
        
        if object === _nextItem && keyPath == "status" {
            if _nextItem.status == .ReadyToPlay {
                _nextItem.removeObserver(self, forKeyPath: "status")
                
                print("duration", _nextItem.duration.value)
                
                _locationText.text = "A \(_timeofday) in \(_place)"
            }
        }
    }
    
    func shuffleVideos() -> Void {
        _assets.shuffleInPlace()
    }
    
    func getNextVideo() -> (url: String, timeOfDay: String, place: String) {
        let video = _assets.removeFirst()
        
        _assets.append(video)
        
        return video
    }
    
    func getRandomVideo() -> (url: String, timeOfDay: String, place: String) {
        let video = _assets[Int(arc4random_uniform(UInt32(_assets.count)))]
        
        _assets.append(video)
        
        return video
    }
    
    func start() -> Void {
        (_url, _timeofday, _place) = getNextVideo()
        
        _nextItem = AVPlayerItem(URL: NSURL(string: _url)!)
        
        _nextItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
        
        _moviePlayer.replaceCurrentItemWithPlayerItem(_nextItem)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CollectionType {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}
