#import "BraintreeDemoCustomMultiPayViewController.h"
#import "BraintreeUI.h"

#import <BraintreeCard/BraintreeCard.h>

@interface BraintreeDemoCustomMultiPayViewController () <BTViewControllerPresentingDelegate>

@property(nonatomic, strong) BTUICardFormView *cardForm;
@property (nonatomic, strong) UINavigationController *cardFormNavigationViewController;
@property (nonatomic, weak) UIBarButtonItem *saveButton;

@end

@implementation BraintreeDemoCustomMultiPayViewController

#pragma mark - Lifecycle & Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Custom Payment Button", nil);

    if (self.paymentButton) {
        [NSLayoutConstraint activateConstraints:@[
            [self.paymentButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20.0],
            [self.paymentButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20.0]
        ]];
    }
}

- (UIView *)createPaymentButton {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *venmoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    venmoButton.translatesAutoresizingMaskIntoConstraints = NO;
    venmoButton.titleLabel.font = [UIFont fontWithName:@"AmericanTypewriter" size:[UIFont systemFontSize]];
    venmoButton.backgroundColor = [[BTUI braintreeTheme] venmoPrimaryBlue];
    [venmoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [venmoButton setTitle:NSLocalizedString(@"Venmo", nil) forState:UIControlStateNormal];

    UIButton *payPalButton = [UIButton buttonWithType:UIButtonTypeSystem];
    payPalButton.translatesAutoresizingMaskIntoConstraints = NO;
    payPalButton.titleLabel.font = [UIFont fontWithName:@"GillSans-BoldItalic" size:[UIFont systemFontSize]];
    payPalButton.backgroundColor = [[BTUI braintreeTheme] palBlue];
    [payPalButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [payPalButton setTitle:NSLocalizedString(@"PayPal", nil) forState:UIControlStateNormal];

    UIButton *cardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cardButton.translatesAutoresizingMaskIntoConstraints = NO;
    cardButton.backgroundColor = [UIColor bt_colorFromHex:@"DDDECB" alpha:1.0f];
    [cardButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cardButton setTitle:@"💳" forState:UIControlStateNormal];

    [venmoButton addTarget:self action:@selector(tappedVenmo:) forControlEvents:UIControlEventTouchUpInside];
    [payPalButton addTarget:self action:@selector(tappedPayPal:) forControlEvents:UIControlEventTouchUpInside];
    [cardButton addTarget:self action:@selector(tappedCard:) forControlEvents:UIControlEventTouchUpInside];

    [view addSubview:payPalButton];
    [view addSubview:venmoButton];
    [view addSubview:cardButton];

    [NSLayoutConstraint activateConstraints:@[
        [venmoButton.widthAnchor constraintEqualToAnchor:payPalButton.widthAnchor],
        [payPalButton.widthAnchor constraintEqualToAnchor:cardButton.widthAnchor],

        [venmoButton.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [venmoButton.trailingAnchor constraintEqualToAnchor:payPalButton.leadingAnchor],
        [payPalButton.trailingAnchor constraintEqualToAnchor:cardButton.leadingAnchor],
        [cardButton.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

        [venmoButton.topAnchor constraintEqualToAnchor:view.topAnchor],
        [payPalButton.topAnchor constraintEqualToAnchor:view.topAnchor],
        [cardButton.topAnchor constraintEqualToAnchor:view.topAnchor],

        [venmoButton.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [payPalButton.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [cardButton.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
    ]];

    return view;
}

#pragma mark - Actions

- (IBAction)tappedVenmo:(__unused UIButton *)button {
    [self tokenizeType:@"Venmo"];
}

- (IBAction)tappedPayPal:(__unused UIButton *)button {
    [self tokenizeType:@"PayPal"];
}

- (IBAction)tappedCard:(UIButton *)button {
    self.cardForm = [[BTUICardFormView alloc] init];
    self.cardForm.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardForm.optionalFields = BTUICardFormOptionalFieldsAll;

    UIViewController *cardFormViewController = [[UIViewController alloc] init];
    cardFormViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                            target:self
                                                                                                            action:@selector(cancelCardVC)];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                    target:self
                                                                    action:@selector(saveCardVC)];
    cardFormViewController.navigationItem.rightBarButtonItem = saveButton;
    cardFormViewController.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
    cardFormViewController.navigationItem.rightBarButtonItem.enabled = NO;
    self.saveButton = saveButton;

    cardFormViewController.title = @"💳";
    [cardFormViewController.view addSubview:self.cardForm];
    cardFormViewController.view.backgroundColor = button.backgroundColor;

    [NSLayoutConstraint activateConstraints:@[
        [self.cardForm.topAnchor constraintEqualToAnchor:cardFormViewController.view.safeAreaLayoutGuide.topAnchor constant:40.0],
        [self.cardForm.leadingAnchor constraintEqualToAnchor:cardFormViewController.view.safeAreaLayoutGuide.leadingAnchor],
        [self.cardForm.trailingAnchor constraintEqualToAnchor:cardFormViewController.view.safeAreaLayoutGuide.trailingAnchor]
    ]];

    self.cardFormNavigationViewController = [[UINavigationController alloc] initWithRootViewController:cardFormViewController];

    [self.cardForm addObserver:self forKeyPath:@"valid" options:0 context:NULL];

    [self presentViewController:self.cardFormNavigationViewController animated:YES completion:nil];
}

#pragma mark - Private methods

- (void)tokenizeType:(NSString *)type {
    [[BTTokenizationService sharedService] tokenizeType:type options:@{ BTTokenizationServiceViewPresentingDelegateOption: self } withAPIClient:self.apiClient completion:^(BTPaymentMethodNonce * _Nonnull paymentMethodNonce, NSError * _Nonnull error) {
        if (paymentMethodNonce) {
            self.progressBlock(@"Got a nonce 💎!");
            NSLog(@"%@", [paymentMethodNonce debugDescription]);
            self.completionBlock(paymentMethodNonce);
        } else if (error) {
            self.progressBlock(error.localizedDescription);
        } else {
            self.progressBlock(@"Canceled 🔰");
        }
    }];
}

- (void)cancelCardVC {
    [self.cardForm removeObserver:self forKeyPath:@"valid"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveCardVC {
    [self cancelCardVC];

    BTCard *card = [[BTCard alloc] init];
    card.number = self.cardForm.number;
    card.expirationMonth = self.cardForm.expirationMonth;
    card.expirationYear = self.cardForm.expirationYear;
    card.cvv = self.cardForm.cvv;
    card.postalCode = self.cardForm.postalCode;
    card.shouldValidate = NO;

    BTCardClient *cardClient = [[BTCardClient alloc] initWithAPIClient:self.apiClient];
    [cardClient tokenizeCard:card completion:^(BTCardNonce * _Nullable tokenizedCard, NSError * _Nullable error) {
        if (tokenizedCard) {
            self.progressBlock(@"Got a nonce 💎!");
            NSLog(@"%@", [tokenizedCard debugDescription]);
            self.completionBlock(tokenizedCard);
        } else if (error) {
            self.progressBlock(error.localizedDescription);
        } else {
            self.progressBlock(@"Canceled 🔰");
        }
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"valid"]) {
        self.saveButton.enabled = self.cardForm.valid;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)paymentDriver:(__unused id)driver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(__unused id)driver requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
