#import "subtype.h"

bool looksLegacy(const struct mach_header *_Nonnull mh) {
    if (mh->magic == FAT_CIGAM || mh->magic == FAT_MAGIC) {
        const struct fat_header *fh = (const struct fat_header *)mh;
        struct fat_arch *arch = (struct fat_arch *)(mh + sizeof(struct fat_header));

        for (uint32_t i = 0; i < OSSwapBigToHostInt32(fh->nfat_arch); ++i) {
            const struct mach_header_64 *sh = (const struct mach_header_64 *)(mh + OSSwapBigToHostInt32(arch->offset));

            if ((sh->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E) {
                if (!(sh->cpusubtype & CPU_SUBTYPE_PTRAUTH_ABI)) {
                    return true;
                }
            }

            arch += 1;
        }
    } else if (mh->magic == MH_MAGIC_64 || mh->magic == MH_CIGAM_64) {
        if ((mh->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E) {
            if (!(mh->cpusubtype & CPU_SUBTYPE_PTRAUTH_ABI)) {
                return true;
            }
        }
    }
    
    return false;
}
