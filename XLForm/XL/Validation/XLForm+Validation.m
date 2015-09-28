//
//  XLForm+Validation.m
//  ALJ
//
//  Created by vlad gorbenko on 8/31/15.
//  Copyright (c) 2015 s4m. All rights reserved.
//

#import "XLForm+Validation.h"

#import "XLErrorProtocol.h"

#import <objc/runtime.h>

@implementation XLFormDescriptor (Validation)

- (BOOL)isValid {
    NSMutableDictionary *errorsDictionary = [NSMutableDictionary dictionary];
    
    for (XLFormSectionDescriptor *section in self.formSections) {
        for (XLFormRowDescriptor *row in section.formRows) {
            if([row conformsToProtocol:@protocol(XLErrorProtocol)]) {
                XLFormRowDescriptor<XLErrorProtocol> *errorRow = (id)row;
                if(errorRow.error) {
                    [errorsDictionary setObject:errorRow forKey:errorRow.tag];
                }
                errorRow.error = nil;
            }
        }
    }
    
    if(!self.isValidationEnabled) {
        return YES;
    }
    
    NSArray *errors = [self localValidationErrors:nil];
    if (errors.count) {
        for (NSError *error in errors) {
            XLFormValidationStatus *validationStatus = error.userInfo[XLValidationStatusErrorKey];
            XLFormRowDescriptor *rowDescriptor = validationStatus.rowDescriptor;
            if([rowDescriptor conformsToProtocol:@protocol(XLErrorProtocol)]) {
                XLFormRowDescriptor<XLErrorProtocol> *errorRowDescriptor = (id)rowDescriptor;
                if(![errorsDictionary objectForKey:errorRowDescriptor.tag]) {
                    [errorsDictionary setObject:errorRowDescriptor forKey:errorRowDescriptor.tag];
                }
                NSString *errorText = validationStatus.msg;
                if(!errorText.length) {
                    errorText = NSLocalizedString(@"Empty errror text", @"XLForm validation");
                }
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorText};
                errorRowDescriptor.error = [NSError errorWithDomain:@"com.XLForm.ext" code:0 userInfo:userInfo];
            }
        }
        NSAssert(self.tableView, @"You need bind reference to UITableView instance");
    }
    
    [self updateCellsWithDictionary:errorsDictionary];

    return !errors.count;
}

#pragma mark - Accessors

- (UITableView *)tableView {
    UITableView *tableView = objc_getAssociatedObject(self, @selector(tableView));
    NSAssert(tableView, @"You need bind reference to UITableView instance");
    return tableView;
}

- (BOOL)isValidationEnabled {
    return [objc_getAssociatedObject(self, @selector(isValidationEnabled)) boolValue];
}

#pragma mark - Modifiers

- (void)setTableView:(UITableView *)tableView {
    objc_setAssociatedObject(self, @selector(tableView), tableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setValidationEnabled:(BOOL)validationEnabled {
    objc_setAssociatedObject(self, @selector(isValidationEnabled), @(validationEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Utils

- (void)updateCells {
    [self.tableView beginUpdates];
    for(NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        XLFormBaseCell *cell = (XLFormBaseCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell update];
    }
    [self.tableView endUpdates];
}

- (void)updateCellsWithDictionary:(NSDictionary *)dictionary {
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
    for(NSString *key in dictionary) {
        XLFormRowDescriptor *rowDescriptor = dictionary[key];
        NSIndexPath *rowIndexPath = [self indexPathOfFormRow:rowDescriptor];
        if([visibleIndexPaths containsObject:rowIndexPath]) {
            [indexPaths addObject:rowIndexPath];
        }
    }
    
    [self.tableView beginUpdates];
    for(NSIndexPath *indexPath in indexPaths) {
        XLFormBaseCell *cell = (XLFormBaseCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell update];
    }
    [self.tableView endUpdates];
}

@end