//
//  iTermStatusBarSwiftyStringComponent.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 6/29/18.
//

#import "iTermStatusBarSwiftyStringComponent.h"

#import "iTermStatusBarComponentKnob.h"
#import "iTermVariables.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const iTermStatusBarSwiftyStringComponentExpressionKey = @"expression";

@implementation iTermStatusBarSwiftyStringComponent {
    iTermSwiftyString *_swiftyString;
}

+ (NSString *)statusBarComponentShortDescription {
    return @"Interpolated String";
}

+ (NSString *)statusBarComponentDetailedDescription {
    return @"Shows the evaluation of a string with inline expressions which may include session "
           @"variables or the output of registered scripting functions";
}

+ (NSArray<iTermStatusBarComponentKnob *> *)statusBarComponentKnobs {
    iTermStatusBarComponentKnob *expressionKnob =
        [[iTermStatusBarComponentKnob alloc] initWithLabelText:@"Expression:"
                                                          type:iTermStatusBarComponentKnobTypeText
                                                   placeholder:@"String with \\(expressions)"
                                                  defaultValue:@""
                                                           key:iTermStatusBarSwiftyStringComponentExpressionKey];
    return @[ expressionKnob ];
}

- (id)statusBarComponentExemplar {
    if (!_swiftyString.swiftyString.length) {
        return @"\\(expression)";
    } else {
        return _swiftyString.swiftyString;
    }
}

- (nullable NSString *)stringValue {
    return _swiftyString.evaluatedString;
}

- (NSSet<NSString *> *)statusBarComponentVariableDependencies {
    return _swiftyString.dependencies;
}

- (void)statusBarComponentVariablesDidChange:(NSSet<NSString *> *)variables {
    [_swiftyString variablesDidChange:variables];
}

- (void)statusBarComponentSetVariableScope:(iTermVariableScope *)scope {
    [super statusBarComponentSetVariableScope:scope];
    [self updateWithKnobValues:self.configuration[iTermStatusBarComponentConfigurationKeyKnobValues]];
}

- (void)updateWithKnobValues:(NSDictionary<NSString *, id> *)knobValues {
    NSString *expression = knobValues[iTermStatusBarSwiftyStringComponentExpressionKey] ?: @"";
    __weak __typeof(self) weakSelf = self;
    if ([self.delegate statusBarComponentIsInSetupUI:self]) {
        _swiftyString = [[iTermSwiftyStringPlaceholder alloc] initWithString:expression];
    } else {
        _swiftyString = [[iTermSwiftyString alloc] initWithString:expression
                                                           source:^id _Nonnull(NSString * _Nonnull name) {
                                                               return [weakSelf.scope valueForVariableName:name] ?: @"";
                                                           }
                                                          mutates:[NSSet set]
                                                         observer:^(NSString * _Nonnull newValue) {
                                                             weakSelf.textField.stringValue = newValue;
                                                         }];
    }
}

- (void)statusBarComponentSetKnobValues:(NSDictionary *)knobValues {
    [self updateWithKnobValues:knobValues];
    [super statusBarComponentSetKnobValues:knobValues];
}

@end

NS_ASSUME_NONNULL_END
