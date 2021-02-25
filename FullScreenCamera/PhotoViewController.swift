import Foundation
import UIKit
import SnapKit

class PhotoViewController: UIViewController {
    let closeButton: UIButton = {
        let button = UIButton(frame: .zero)

        button.setBackgroundImage(UIImage(named: "close_white"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    let saveButton: UIButton = {
        let button = UIButton(frame: .zero)

        button.setBackgroundImage(UIImage(named: "save_white"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }()
    let imageView: UIImageView = {
        let view = UIImageView(frame: .zero)

        view.contentMode = .scaleAspectFill

        return view
    }()
    let image: UIImage?

    // MARK: - Constructor
    init(image: UIImage?) {
        self.image = image

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lift Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        config()
    }

    func config() {
        imageView.image = image

        closeButton.addTarget(self, action: #selector(closePhotoView), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(savePhotoView), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc func closePhotoView(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func savePhotoView(_ sender: UIButton) {
        guard  let imageToSave = image else {
            return
        }

        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)

        self.dismiss(animated: true, completion: nil)
    }
}

extension PhotoViewController {
    func setupView() {
        func setupImageView() {
            self.view.addSubview(imageView)

            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        func setupCloseButton() {
            self.view.addSubview(closeButton)

            closeButton.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
                make.left.equalToSuperview().offset(20)
                make.width.height.equalTo(25)
            }
        }

        func setupSaveButton() {
            self.view.addSubview(saveButton)

            saveButton.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
                make.right.equalToSuperview().offset(-20)
                make.width.height.equalTo(25)
            }
        }

        setupImageView()
        setupCloseButton()
        setupSaveButton()
    }
}
