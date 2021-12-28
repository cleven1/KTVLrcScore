//
//  AgoraLrcScoreView.swift
//  AgoraKaraokeScore
//
//  Created by zhaoyongqiang on 2021/12/16.
//

import UIKit

@objc
public
protocol AgoraLrcViewDelegate {
    /// 秒
    func getPlayerCurrentTime() -> TimeInterval
    /// 获取歌曲总时长
    func getTotalTime() -> TimeInterval

    /// 设置播放器时间
    @objc
    optional func seekToTime(time: TimeInterval)
    /// 当前正在播放的歌词和进度
    @objc
    optional func currentPlayerLrc(lrc: String, progress: CGFloat)
}

@objc
public
protocol AgoraLrcDownloadDelegate {
    /// 开始下载
    @objc
    optional func beginDownloadLrc(url: String)
    /// 下载完成
    @objc
    optional func downloadLrcFinished(url: String)
    /// 下载进度
    @objc
    optional func downloadLrcProgress(url: String, progress: Double)
    /// 下载失败
    @objc
    optional func downloadLrcError(url: String, error: Error?)
    /// 下载取消
    @objc
    optional func downloadLrcCanceld(url: String)
    /// 开始解析歌词
    @objc
    optional func beginParseLrc()
    /// 解析歌词结束
    @objc
    optional func parseLrcFinished()
}

@objc
public
protocol AgoraKaraokeScoreDelegate {
    /// 分数实时回调
    @objc optional func AgoraKaraokeScore(score: Double)
}

public class AgoraLrcScoreView: UIView {
    /// 配置
    public var config: AgoraLrcScoreConfigModel = .init() {
        didSet {
            scoreView.scoreConfig = config.scoreConfig
            lrcView.lrcConfig = config.lrcConfig
            scoreViewHCons?.constant = scoreView.scoreConfig.scoreViewHeight
            scoreViewHCons?.isActive = true
            statckView.spacing = config.spacing
            setupBackgroundImage()
        }
    }

    /// 事件回调
    public weak var delegate: AgoraLrcViewDelegate?
    /// 下载歌词事件回调
    public weak var downloadDelegate: AgoraLrcDownloadDelegate? {
        didSet {
            AgoraDownLoadManager.manager.delegate = downloadDelegate
        }
    }

    /// 实时评分回调
    public weak var scoreDelegate: AgoraKaraokeScoreDelegate? {
        didSet {
            scoreView.delegate = scoreDelegate
        }
    }

    /// 清除缓存文件
    public static func cleanCache() {
        try? FileManager.default.removeItem(atPath: String.cacheFolderPath())
    }

    private lazy var statckView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    private lazy var scoreView: AgoraKaraokeScoreView = {
        let view = AgoraKaraokeScoreView()
        return view
    }()

    private lazy var lrcView: AgoraLrcView = {
        let view = AgoraLrcView()
        view.seekToTime = { [weak self] time in
            self?.delegate?.seekToTime?(time: time)
        }
        view.currentPlayerLrc = { [weak self] lrc, progress in
            self?.delegate?.currentPlayerLrc?(lrc: lrc,
                                              progress: progress)
        }
        return view
    }()

    private var link: CADisplayLink?
    private var scoreViewHCons: NSLayoutConstraint?

    public init(delegate: AgoraLrcViewDelegate) {
        super.init(frame: .zero)
        setupUI()
        self.delegate = delegate
    }

    override private init(frame _: CGRect) {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: 赋值方法

    /// 歌词的URL
    public func setLrcUrl(url: String) {
        AgoraDownLoadManager.manager.downloadZip(urlString: url) { lryic in
            self.lrcView.miguSongModel = lryic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.scoreView.lrcSentence = lryic?.sentences
                self.downloadDelegate?.downloadLrcFinished?(url: url)
            }
        }
    }

    /// 实时声音数据
    public func setVoicePitch(_ voicePitch: [Double]) {
        scoreView.setVoicePitch(voicePitch)
    }

    /// 开始滚动
    public func start() {
        link = CADisplayLink(target: self, selector: #selector(timerHandler))
        link?.add(to: RunLoop.main, forMode: .common)
    }

    /// 停止
    public func stop() {
        if link != nil {
            link?.invalidate()
            link = nil
        }
    }

    @objc
    private func timerHandler() {
        let currentTime = delegate?.getPlayerCurrentTime() ?? 0
        lrcView.start(currentTime: currentTime)
        let totalTime = delegate?.getTotalTime() ?? 0
        scoreView.start(currentTime: currentTime,
                        totalTime: totalTime)
    }

    private func setupBackgroundImage() {
//        guard let bgImageView = config.backgroundImageView else { return }
//        insertSubview(bgImageView, at: 0)
//        bgImageView.translatesAutoresizingMaskIntoConstraints = false
//        bgImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
//        bgImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
//        bgImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
//        bgImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func setupUI() {
        statckView.translatesAutoresizingMaskIntoConstraints = false
        scoreView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statckView)
        statckView.addArrangedSubview(scoreView)
        statckView.addArrangedSubview(lrcView)

        statckView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        statckView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        statckView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        statckView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        scoreViewHCons = scoreView.heightAnchor.constraint(equalToConstant: config.scoreConfig.scoreViewHeight)
        scoreViewHCons?.isActive = true
    }
}