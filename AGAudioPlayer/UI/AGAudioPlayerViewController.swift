//
//  AGAudioPlayerViewController.swift
//  AGAudioPlayer
//
//  Created by Alec Gorge on 1/19/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit
import QuartzCore

import Interpolate
import MarqueeLabel

@objc class AGAudioPlayerViewController: UIViewController {

    @IBOutlet var uiPanGestureClose: VerticalPanDirectionGestureRecognizer!
    
    @IBOutlet weak var uiTable: UITableView!
    @IBOutlet weak var uiHeaderView: UIView!
    @IBOutlet weak var uiFooterView: UIView!
    @IBOutlet weak var uiProgressDownload: UIView!
    @IBOutlet weak var uiProgressDownloadCompleted: UIView!
    
    @IBOutlet weak var uiScrubber: ScrubberBar!
    @IBOutlet weak var uiProgressDownloadCompletedContraint: NSLayoutConstraint!
    
    @IBOutlet weak var uiLabelTitle: MarqueeLabel!
    @IBOutlet weak var uiLabelSubtitle: MarqueeLabel!
    @IBOutlet weak var uiLabelElapsed: UILabel!
    @IBOutlet weak var uiLabelDuration: UILabel!
    
    @IBOutlet weak var uiButtonShuffle: UIButton!
    @IBOutlet weak var uiButtonPrevious: UIButton!
    @IBOutlet weak var uiButtonPlay: UIButton!
    @IBOutlet weak var uiButtonPause: UIButton!
    @IBOutlet weak var uiButtonNext: UIButton!
    @IBOutlet weak var uiButtonLoop: UIButton!
    @IBOutlet weak var uiButtonDots: UIButton!
    @IBOutlet weak var uiButtonPlus: UIButton!
    
    // colors
    let ColorMain = UIColor(red:0.149, green:0.608, blue:0.737, alpha:1)
    let ColorAccent = UIColor.white
    let ColorAccentWeak = UIColor.white.withAlphaComponent(0.7)
    
    let ColorBarNothing = UIColor.white.withAlphaComponent(0.3)
    let ColorBarDownloads = UIColor.white.withAlphaComponent(0.4)
    let ColorBarPlaybackElapsed = UIColor.white
    let ColorScrubberHandle = UIColor.white
    
    // constants
    let SectionQueue = 0
    
    // bouncy header
    var headerInterpolate: Interpolate?
    var interpolateBlock: ((_ scale: Double) -> Void)?
    
    // swipe to dismiss
    static let defaultTransitionDelegate = AGAudioPlayerViewControllerTransitioningDelegate()
    
    // non-jumpy seeking
    var isCurrentlyScrubbing = false
    
    let player: AGAudioPlayer
    
    init(player: AGAudioPlayer) {
        self.player = player
        
        super.init(nibName: String(describing: AGAudioPlayerViewController.self), bundle: Bundle.main)
        
        self.transitioningDelegate = AGAudioPlayerViewController.defaultTransitionDelegate
        
        setupPlayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTable()
        setupStretchyHeader()
        setupColors()
        setupPlayerUiActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewWillAppear_StretchyHeader()
        viewWillAppear_Table()
        updateUI()
    }
}

extension AGAudioPlayerViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let pt = touch.location(in: uiHeaderView)
        
        return !uiHeaderView.frame.contains(pt);
    }
}

extension AGAudioPlayerViewController : AGAudioPlayerDelegate {
    func setupPlayer() {
        player.delegate = self
    }
    
    func updateUI() {
        updatePlayPauseButtons()
        updateShuffleLoopButtons()
        updateNonTimeLabels()
        updateTimeLabels()
        updatePlaybackProgress()
        updatePreviousNextButtons()
    }
    
    func updatePlayPauseButtons() {
        guard uiButtonPause != nil, uiButtonPlay != nil else {
            return
        }
        
        uiButtonPause.isHidden = !player.isPlaying && !player.isBuffering
        uiButtonPlay.isHidden = player.isPlaying
    }
    
    func updatePreviousNextButtons() {
        guard uiButtonPrevious != nil, uiButtonNext != nil else {
            return
        }

        uiButtonPrevious.isEnabled = !player.isPlayingFirstItem
        uiButtonNext.isEnabled = !player.isPlayingLastItem
    }
    
    func updateShuffleLoopButtons() {
        guard uiButtonShuffle != nil, uiButtonLoop != nil else {
            return
        }
        
        uiButtonLoop.alpha = player.loopItem ? 1.0 : 0.7
        uiButtonShuffle.alpha = player.shuffle ? 1.0 : 0.7
    }
    
    func updateNonTimeLabels() {
        guard uiLabelTitle != nil, uiLabelSubtitle != nil else {
            return
        }
        
        if let cur = player.currentItem {
            print("updating text to:")
            print(cur.displayText)
            print(cur.displaySubtext)
            
            uiLabelTitle.text = cur.displayText
            uiLabelSubtitle.text = cur.displaySubtext
        }
    }
    
    func updateTimeLabels() {
        guard uiLabelElapsed != nil, uiLabelDuration != nil else {
            return
        }
        
        uiLabelElapsed.text = player.elapsed.formatted()
        uiLabelDuration.text = player.duration.formatted()
    }
    
    func updatePlaybackProgress() {
        guard uiScrubber != nil else {
            return
        }

        if !isCurrentlyScrubbing {
            uiScrubber.setProgress(progress: Float(player.percentElapsed))
            updateTimeLabels()
        }
    }
    
    func audioPlayer(_ audioPlayer: AGAudioPlayer, uiNeedsRedrawFor reason: AGAudioPlayerRedrawReason) {
        switch reason {
        case .buffering, .playing:
            updatePlayPauseButtons()
            
        case .stopped:
            uiLabelTitle.text = ""
            uiLabelSubtitle.text = ""
            
            fallthrough
            
        case .paused, .error:
            updatePlayPauseButtons()
            
            
        case .trackChanged:
            print("track changed")
            updatePreviousNextButtons()
            updateNonTimeLabels()
            uiTable.reloadData()
            
        default:
            break
        }
    }
    
    func audioPlayer(_ audioPlayer: AGAudioPlayer, errorRaised error: Error, for url: URL) {
        print("CRAP")
        print(error)
        print(url)
    }
    
    func audioPlayer(_ audioPlayer: AGAudioPlayer, downloadedBytesForActiveTrack downloadedBytes: UInt64, totalBytes: UInt64) {
        guard uiProgressDownloadCompleted != nil else {
            return
        }
        
        let progress = Double(downloadedBytes) / Double(totalBytes)
        
        uiProgressDownloadCompletedContraint = uiProgressDownloadCompletedContraint.setMultiplier(multiplier: CGFloat(progress))
        
        uiProgressDownload.layoutIfNeeded()
    }
    
    func audioPlayer(_ audioPlayer: AGAudioPlayer, progressChanged elapsed: TimeInterval, withTotalDuration totalDuration: TimeInterval) {
        updatePlaybackProgress()
    }
}

extension AGAudioPlayerViewController : ScrubberBarDelegate {
    func setupPlayerUiActions() {
        uiScrubber.delegate = self
        
        uiLabelTitle.trailingBuffer = 32
        uiLabelSubtitle.trailingBuffer = 24
        
        uiLabelTitle.animationDelay = 5
        uiLabelTitle.rate = 25
        
        uiLabelSubtitle.animationDelay = 5
        uiLabelSubtitle.rate = 25
    }
    
    func scrubberBar(bar: ScrubberBar, didScrubToProgress: Float, finished: Bool) {
        isCurrentlyScrubbing = !finished
        
        if let elapsed = uiLabelElapsed {
            elapsed.text = TimeInterval(player.duration * Double(didScrubToProgress)).formatted()
        }
        
        if finished {
            player.seek(toPercent: CGFloat(didScrubToProgress))
        }
    }
    
    @IBAction func uiActionToggleShuffle(_ sender: UIButton) {
        player.shuffle = !player.shuffle
        
        updateShuffleLoopButtons()
    }
    
    @IBAction func uiActionToggleLoop(_ sender: UIButton) {
        player.loopItem = !player.loopItem
        
        updateShuffleLoopButtons()
    }
    
    @IBAction func uiActionPrevious(_ sender: UIButton) {
        player.backward()
    }
    
    @IBAction func uiActionPlay(_ sender: UIButton) {
        player.resume()
    }
    
    @IBAction func uiActionPause(_ sender: UIButton) {
        player.pause()
    }
    
    @IBAction func uiActionNext(_ sender: UIButton) {
        player.forward()
    }
    
    @IBAction func uiActionDots(_ sender: UIButton) {
    }
    
    @IBAction func uiActionPlus(_ sender: UIButton) {
    }
}

extension AGAudioPlayerViewController {
    @IBAction func handlePanToClose(_ sender: UIPanGestureRecognizer) {
        if let del = transitioningDelegate as? AGAudioPlayerViewControllerTransitioningDelegate {
            switch sender.state {
            case .began:
                uiScrubber.scrubbingEnabled = false
            case .cancelled, .ended:
                uiScrubber.scrubbingEnabled = true
            default: break
            }
            
            del.handleGesture(self, inView: uiHeaderView, sender: sender);
        }
    }
}

extension AGAudioPlayerViewController {
    func setupStretchyHeader() {
        let blk = { [weak self] (fontScale: Double) in
            if let s = self {
                s.uiHeaderView.transform = CGAffineTransform(scaleX: CGFloat(fontScale), y: CGFloat(fontScale))
                
                let h = s.uiHeaderView.bounds.height * CGFloat(fontScale)
                s.uiTable.scrollIndicatorInsets = UIEdgeInsetsMake(h, 0, 0, 0)
            }
        }
        
        headerInterpolate = Interpolate(from: 1.0, to: 1.3, function: BasicInterpolation.easeOut, apply: blk)
        
        interpolateBlock = blk
    }
    
    func viewWillAppear_StretchyHeader() {
        interpolateBlock?(1.0)
        
        let h = uiHeaderView.bounds.height
        uiTable.contentInset = UIEdgeInsetsMake(h, 0, 0, 0)
        uiTable.contentOffset = CGPoint(x: 0, y: -h)
    }
    
    func scrollViewDidScroll_StretchyHeader(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y + uiHeaderView.bounds.height
        let np = CGFloat(abs(y).clamped(lower: CGFloat(0), upper: CGFloat(150))) / CGFloat(150)
        
        if y < 0 && headerInterpolate?.progress != np {
            headerInterpolate?.progress = np
        }
    }
}

extension AGAudioPlayerViewController {
    func setupColors() {
        uiHeaderView.backgroundColor = ColorMain
        uiFooterView.backgroundColor = ColorMain
        
        uiLabelTitle.textColor = ColorAccent
        uiLabelSubtitle.textColor = ColorAccent
        
        uiLabelElapsed.textColor = ColorAccentWeak
        uiLabelDuration.textColor = ColorAccentWeak
        
        uiProgressDownload.backgroundColor = ColorBarNothing
        uiProgressDownloadCompleted.backgroundColor = ColorBarDownloads
        uiScrubber.elapsedColor = ColorBarPlaybackElapsed
        uiScrubber.dragIndicatorColor = ColorScrubberHandle
    
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension AGAudioPlayerViewController {
    func setupTable() {
        uiTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
//        uiTable.backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: uiHeaderView.bounds.size.height + 44 * 2))
//        uiTable.backgroundView?.backgroundColor = ColorMain
        
        uiTable.allowsSelection = true
        uiTable.allowsSelectionDuringEditing = false
        uiTable.allowsMultipleSelectionDuringEditing = true
        
        uiTable.setEditing(false, animated: false)
        uiTable.reloadData()
    }
    
    func viewWillAppear_Table() {
    }
}

extension AGAudioPlayerViewController : UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDidScroll_StretchyHeader(scrollView)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            
        }
        else {
            player.currentIndex = indexPath.row
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("\(indexPath) deselected")
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == SectionQueue
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
}

extension AGAudioPlayerViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return player.queue.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Queue"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        guard indexPath.row < player.queue.count else {
            cell.textLabel?.text = "Error"
            return cell
        }
        
        let item = player.queue[UInt(indexPath.row)]
        
        cell.textLabel?.text = (item.playbackGUID == player.currentItem?.playbackGUID ? "* " : "") + item.title
        
        return cell
    }
}
