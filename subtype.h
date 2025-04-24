#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/fat.h>

bool looksLegacy(const struct mach_header *_Nonnull mh);
