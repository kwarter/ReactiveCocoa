//
//  UIBarButtonItem+RACCommandSupport.m
//  ReactiveCocoa
//
//  Created by Kyle LeNeau on 3/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "UIBarButtonItem+RACCommandSupport.h"
#import <ReactiveCocoa/EXTKeyPathCoding.h>
#import <ReactiveCocoa/NSObject+RACPropertySubscribing.h>
#import <ReactiveCocoa/RACCommand.h>
#import <ReactiveCocoa/RACDisposable.h>
#import <ReactiveCocoa/RACScheduler.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <objc/runtime.h>

static void *UIControlRACCommandKey = &UIControlRACCommandKey;
static void *UIControlCanExecuteDisposableKey = &UIControlCanExecuteDisposableKey;

@implementation UIBarButtonItem (RACCommandSupport)

- (RACCommand *)rac_command {
	return objc_getAssociatedObject(self, UIControlRACCommandKey);
}

- (void)setRac_command:(RACCommand *)command {
	objc_setAssociatedObject(self, UIControlRACCommandKey, command, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	if (command == nil) return;
	
	// Check for stored signal in order to remove it and add a new one
	RACDisposable *disposable = objc_getAssociatedObject(self, UIControlCanExecuteDisposableKey);
	[disposable dispose];
	
	disposable = [[[RACAble(command, canExecute)
		deliverOn:RACScheduler.mainThreadScheduler]
		startWith:@(command.canExecute)]
		toProperty:@keypath(self.enabled) onObject:self];

	objc_setAssociatedObject(self, UIControlCanExecuteDisposableKey, disposable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[self rac_hijackActionAndTargetIfNeeded];
}

- (void)rac_hijackActionAndTargetIfNeeded {
	SEL hijackSelector = @selector(rac_commandPerformAction:);
	if (self.target == self && self.action == hijackSelector) return;
	
	if (self.target != nil) NSLog(@"WARNING: UIBarButtonItem.rac_command hijacks the control's existing target and action.");
	
	self.target = self;
	self.action = hijackSelector;
}

- (void)rac_commandPerformAction:(id)sender {
	[self.rac_command execute:sender];
}

@end
