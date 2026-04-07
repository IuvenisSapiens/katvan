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
#import <AppKit/AppKit.h>

@interface KatvanAuxToolBar : NSView

- (void)addView:(NSView* _Nonnull)view inGravity:(NSStackViewGravity)gravity;

- (NSButton* _Nonnull)addButtonWithIcon:(NSImage* _Nonnull)icon
                      toolTip:(NSString* _Nullable)toolTip
                      inGravity:(NSStackViewGravity)gravity
                      target:(id _Nullable)target
                      action:(SEL _Nullable)selector;

@end

@interface KatvanSpinBox : NSView <NSTextFieldDelegate>

@property (nonatomic, assign) NSInteger minimum;
@property (nonatomic, assign) NSInteger maximum;
@property (nonatomic, assign) NSInteger value;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, assign, nullable) SEL action;

@end

@interface KatvanFontPicker : NSView <NSFontChanging>

@property (nonatomic, copy, nullable) NSFont* font;
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, assign, nullable) SEL action;

@end
