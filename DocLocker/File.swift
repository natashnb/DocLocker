//  Copyright © 2017 Big Nerd Ranch. All rights reserved.

import Foundation

enum FileType: Int {
    case file
    case directory
    case symbolicLink
    case device
    case unknown

    init(type: String) {
        switch FileAttributeType(rawValue: type) {
        case .typeRegular:
            self = .file
        case .typeDirectory:
            self = .directory
        case .typeSymbolicLink:
            self = .symbolicLink
        case .typeBlockSpecial,
             .typeCharacterSpecial:
            self = .device
        default:
            self = .unknown
        }
    }
    
    init(resourceType: URLFileResourceType) {
        switch resourceType {
        case .namedPipe: self = .unknown
        case .characterSpecial, .blockSpecial: self = .device
        case .directory: self = .directory
        case .regular: self = .file
        case .symbolicLink: self = .symbolicLink
        case .socket: self = .unknown
        case .unknown: self = .unknown
        default:
            print("unknown unexpected resource type \(resourceType)")
            self = .unknown
        }
        
    }
}


/// Represents an entity in the file system
/// This could have fun stuff like size, various flavors of checksum, 
/// is it a directory, etc.
public var sizeCount = 0
public var typeCount = 0

struct File {
    /// Where in the filesystem this particular file lives.
    let url: URL

    var fileSize: Int? {
        sizeCount += 1
        //        return try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? Int ?? 0
        let values = try! url.resourceValues(forKeys: [.fileSizeKey])
        let size = values.fileSize ?? 0
        return size
    }
    

    var fileType: FileType {
        typeCount += 1
//        let type = ((try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.type] as? String) ?? "") ?? ""
//        return FileType(type: type)

        let values = try! url.resourceValues(forKeys: [.fileResourceTypeKey])
        guard let type = values.fileResourceType else { return .unknown }
        return FileType(resourceType: type)
    }

    init(url: URL) {
        self.url = url

//        self.fileType = ((try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.type] as? String) ?? "") ?? ""
//        self.fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? Int ?? 0
    }
}


extension File: CustomStringConvertible {
    var description: String {
        return "File: \(url) file size = \(fileSize!)  type = \(fileType)"
    }
}

extension FileManager {

    /// Fetch (non-recursively) the contents of the directory and return
    /// Files for each entity there.
    func filesInDirectory(at url: URL) -> [File] {
        do {
            let urls = try self.contentsOfDirectory(at: url,
                                                    includingPropertiesForKeys: [.fileSizeKey, .fileResourceTypeKey],
                                                    options: [])
            let files = urls.map(File.init(url:))
            return files

        } catch {
            print("Could not read files at url \(url)")
            return []
        }
    }
    
    // total size of directory, deep
    func totalSizeOfDirectory(at url: URL) -> Int {
        let files = self.filesInDirectory(at: url)
        var size = 0

        for file in files {
            autoreleasepool {
                if file.fileType == .directory {
                    size += totalSizeOfDirectory(at: file.url)
                } else {
                    size += file.fileSize ?? 0
                }
            }
        }
        
        return size
    }
    
    func totalSizeOfDirectoryWithDeepRecursion(at url: URL) -> Int {
        let directoryEnumerator = self.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .fileResourceTypeKey]) 
        
        var totalSize = 0
        for something in directoryEnumerator! {
            guard let url = something as? URL else {
                continue
            }
            let values = try! url.resourceValues(forKeys: [.fileSizeKey, .fileResourceTypeKey])
            let size = values.fileSize ?? 0
            totalSize += size
            
            _ = File(url: url)
            
//            let file = File(url: url)  /// 1.9 sec
//            if file.fileType != .directory {
//                totalSize += file.fileSize ?? 0
//            }
//        
//            let fileAttributesRaw = directoryEnumerator!.fileAttributes
//            let directoryAttributesRaw = directoryEnumerator!.directoryAttributes
//            guard let fileAttributes = directoryEnumerator!.fileAttributes else {
//                continue
//            }
//            print("HUH?")
//            let size = fileAttributes[FileAttributeKey.size] as? Int ?? 0
//            totalSize += size
        }

        return totalSize
    }
    
//    // total size for a flat directory
//    func sizeOfDirectory(at url: URL) -> Int {
//        let files = self.filesInDirectory(at: url)
//        
//        let size = files.reduce(0, { accumulator, file in accumulator + (file.fileSize ?? 0) })
//        print("size! \(size)")
//        return size
//    }
}





