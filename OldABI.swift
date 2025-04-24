import Foundation
import MachO

private let ekhandle = dlopen("/var/jb/usr/lib/libellekit.dylib", RTLD_NOW);

private let hookMemory = {
    unsafeBitCast(dlsym(ekhandle, "MSHookMemory"), to: (@convention(c) (UnsafeRawPointer, UnsafeRawPointer, size_t) -> Void).self)
}()

private func oneshot_fix_oldabi() {
    let count = _dyld_image_count()
    
    var bytes: [UInt8] = [
        0x00, 0x18, 0xC1, 0xDA
    ]
    
    var mask: [UInt8] = [
        0x00, 0xFC, 0xFF, 0xFF
    ]
    
    for image in 0..<count {
        let name = String(cString: _dyld_get_image_name(image))
        
        if name == "/usr/lib/libobjc.A.dylib" || name == "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" || name == "/usr/lib/swift/libswiftCore.dylib" {
            while true {
                guard let autda = patchfind_find(image, &bytes, &mask, 4) else { break }
                
                hookMemory(autda, [
                    CFSwapInt32(0xF047C1DA) // xpacd x16
                ], 4)
            }
        }
    }
}

@_cdecl("swift_ctor")
func ctor() {
    guard let executablePath = ProcessInfo.processInfo.arguments.first else { return }
    
    let whitelist = [
        "/System/Library/CoreServices/SpringBoard.app/SpringBoard",
        "/Applications/",
        "/usr/sbin/mediaserverd",
        "/usr/libexec/backboardd",
        "/usr/libexec/nfcd"
    ].map {
        executablePath.hasPrefix($0)
    }.contains(true)

    if !whitelist && !executablePath.contains("/procursus/Applications/") {
        return
    }
    
    _dyld_register_func_for_add_image { header, _ in
        guard let header else { return }
        
        if looksLegacy(header) {
            oneshot_fix_oldabi()
        }
    }
}
