// -*- mode: objective-cpp -*-
/*
 * This file is part of Katvan
 * Copyright (c) 2024 - 2026 Igor Khanin
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#import "macshell_exporter.h"

@interface KatvanPdfExportAccessory : NSViewController

@end

@implementation  KatvanPdfExportAccessory

- (void)loadView
{
    self.view = [NSView new];
}

@end

@interface KatvanExporter ()

@property (nonatomic) katvan::TypstDriverWrapper* driver;
@property (nonatomic, weak) NSWindow* window;

@end

@implementation KatvanExporter

- (instancetype)initWithDriver:(katvan::TypstDriverWrapper*)driver andWindow:(NSWindow*)window
{
    self = [super init];
    if (self) {
        self.driver = driver;
        self.window = window;
    }
    return self;
}

- (BOOL)canExport
{
    katvan::TypstDriverWrapper::Status status = self.driver->status();
    return status == katvan::TypstDriverWrapper::Status::SUCCESS
        || status == katvan::TypstDriverWrapper::Status::SUCCESS_WITH_WARNINGS;
}

- (NSString*)fileBaseName
{
    NSString* filename = self.window.representedFilename;
    if ([filename length] > 0) {
        return filename.lastPathComponent.stringByDeletingPathExtension;
    }
    return nil;
}

- (void)exportAsPdf
{
    NSPDFPanel* dialog = [NSPDFPanel panel];
    NSPDFInfo* info = [[NSPDFInfo alloc] init];

    dialog.accessoryController = [[KatvanPdfExportAccessory alloc] init];

    NSString* baseName = [self fileBaseName];
    if (baseName) {
        dialog.defaultFileName = baseName; // No .pdf suffix
    }

    [dialog beginSheetWithPDFInfo:info
            modalForWindow:self.window
            completionHandler:^(NSInteger rc) {
                if (rc) {
                    QString path = QString::fromNSString(info.URL.path);
                    self.driver->exportToPdf(path);
                }
            }
    ];
}

@end
