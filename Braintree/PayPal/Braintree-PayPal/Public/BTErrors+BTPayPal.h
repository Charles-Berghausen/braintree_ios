#import "BTErrors.h"

/// Braintree+PayPal NSError Domain
extern NSString *const BTBraintreePayPalErrorDomain;

/// Errors codes
NS_ENUM(NSInteger, BTPayPalErrorCode) {
    BTPayPalUnknownError = 0,
    BTMerchantIntegrationErrorPayPalConfiguration,
};