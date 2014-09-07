@import UIKit;

#import "BTVenmoErrors.h"
#import "BTVenmoAppSwitchHandler.h"
#import "BTVenmoAppSwitchHandler_Internal.h"
#import "BTVenmoAppSwitchReturnURL.h"
#import "BTVenmoAppSwitchRequestURL.h"
#import "BTClient+BTVenmo.h"
#import "BTClient_Metadata.h"

SpecBegin(BTVenmoAppSwitchHandler)

describe(@"sharedHandler", ^{

    it(@"returns one and only one instance", ^{
        expect([BTVenmoAppSwitchHandler sharedHandler]).to.beIdenticalTo([BTVenmoAppSwitchHandler sharedHandler]);
    });

});

describe(@"An instance", ^{
    __block BTVenmoAppSwitchHandler *handler;
    __block id client;
    __block id delegate;

    beforeEach(^{
        handler = [[BTVenmoAppSwitchHandler alloc] init];
        client = [OCMockObject mockForClass:[BTClient class]];
        delegate = [OCMockObject mockForProtocol:@protocol(BTAppSwitchingDelegate)];

        [[[client stub] andReturn:client] copyWithMetadata:OCMOCK_ANY];
        [[client stub] postAnalyticsEvent:OCMOCK_ANY];
    });

    afterEach(^{
        [client verify];
        [client stopMocking];

        [delegate verify];
        [delegate stopMocking];
    });

    describe(@"availableWithClient:", ^{

        __block id venmoAppSwitchRequestURL;

        beforeEach(^{
            venmoAppSwitchRequestURL = [OCMockObject mockForClass:[BTVenmoAppSwitchRequestURL class]];
        });

        afterEach(^{
            [venmoAppSwitchRequestURL verify];
            [venmoAppSwitchRequestURL stopMocking];
        });

        context(@"valid merchant ID valid returnURLScheme", ^{
            beforeEach(^{
                [[[client stub] andReturn:@"a-merchant-id"] merchantId];
                handler.returnURLScheme = @"a-scheme";
            });

            it(@"returns YES if [BTVenmoAppSwitchRequestURL isAppSwitchAvailable] and venmo status is production", ^{
                [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusProduction)] btVenmo_status];
                [[[venmoAppSwitchRequestURL stub] andReturnValue:@YES] isAppSwitchAvailable];
                expect([handler appSwitchAvailableForClient:client]).to.beTruthy();
            });

            it(@"returns YES if [BTVenmoAppSwitchRequestURL isAppSwitchAvailable] and venmo status is offline", ^{
                [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusOffline)] btVenmo_status];
                [[[venmoAppSwitchRequestURL stub] andReturnValue:@YES] isAppSwitchAvailable];
                expect([handler appSwitchAvailableForClient:client]).to.beTruthy();
            });

            it(@"returns NO if venmo status is off", ^{
                [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusOff)] btVenmo_status];
                [[[venmoAppSwitchRequestURL stub] andReturnValue:@YES] isAppSwitchAvailable];
                expect([handler appSwitchAvailableForClient:client]).to.beFalsy();
            });

            it(@"returns NO if [BTVenmoAppSwitchRequestURL isAppSwitchAvailable] returns NO", ^{
                [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusProduction)] btVenmo_status];
                [[[venmoAppSwitchRequestURL stub] andReturnValue:@NO] isAppSwitchAvailable];
                expect([handler appSwitchAvailableForClient:client]).to.beFalsy();
            });
        });

        context(@"available venmo status and app switch", ^{
            beforeEach(^{
                [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusProduction)] btVenmo_status];
                [[[venmoAppSwitchRequestURL stub] andReturnValue:@YES] isAppSwitchAvailable];
            });

            it(@"returns YES if merchant is not nil and returnURLScheme is not nil", ^{
                [[[client stub] andReturn:@"a-merchant-id"] merchantId];
                handler.returnURLScheme = @"a-scheme";
                expect([handler appSwitchAvailableForClient:client]).to.beTruthy();
            });

            it(@"returns NO if merchant is nil", ^{
                handler.returnURLScheme = @"a-scheme";
                [[[client stub] andReturn:nil] merchantId];
                expect([handler appSwitchAvailableForClient:client]).to.beFalsy();
            });

            it(@"returns NO if returnURLScheme is nil", ^{
                [[[client stub] andReturn:@"a-merchant-id"] merchantId];
                expect([handler appSwitchAvailableForClient:client]).to.beFalsy();
            });
        });
    });


    describe(@"canHandleReturnURL:sourceApplication:", ^{

        __block id mockVenmoAppSwitchReturnURL;
        NSString *testSourceApplication = @"a-source.app.App";
        NSURL *testURL = [NSURL URLWithString:@"another-scheme://a-host"];

        beforeEach(^{
            mockVenmoAppSwitchReturnURL = [OCMockObject mockForClass:[BTVenmoAppSwitchReturnURL class]];
        });

        afterEach(^{
            [mockVenmoAppSwitchReturnURL verify];
            [mockVenmoAppSwitchReturnURL stopMocking];
        });

        it(@"returns YES if [BTVenmoAppSwitchReturnURL isValidURL:sourceApplication:] returns YES", ^{
            [[[mockVenmoAppSwitchReturnURL expect] andReturnValue:@YES] isValidURL:testURL sourceApplication:testSourceApplication];

            BOOL handled = [handler canHandleReturnURL:testURL sourceApplication:testSourceApplication];

            expect(handled).to.beTruthy();
        });

        it(@"returns NO if [BTVenmoAppSwitchReturnURL isValidURL:sourceApplication:] returns NO", ^{
            [[[mockVenmoAppSwitchReturnURL expect] andReturnValue:@NO] isValidURL:testURL sourceApplication:testSourceApplication];

            BOOL handled = [handler canHandleReturnURL:testURL sourceApplication:testSourceApplication];

            expect(handled).to.beFalsy();
        });
    });

    describe(@"initiateAppSwitchWithClient:delegate:", ^{

        it(@"returns BTVenmoErrorAppSwitchDisabled error if client has `btVenmo_status` BTVenmoStatusOff", ^{

            [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusOff)] btVenmo_status];

            NSError *error = [handler initiateAppSwitchWithClient:client delegate:delegate];
            expect(error.domain).to.equal(BTVenmoErrorDomain);
            expect(error.code).to.equal(BTVenmoErrorAppSwitchDisabled);
        });

        context(@"btVenmo_status BTVenmoStatusProduction", ^{
            __block id venmoRequestURL;
            __block id sharedApplication;

            beforeEach(^{
                venmoRequestURL = [OCMockObject mockForClass:[BTVenmoAppSwitchRequestURL class]];
                sharedApplication = [OCMockObject mockForClass:[UIApplication class]];
                [[[sharedApplication stub] andReturn:sharedApplication] sharedApplication];
                [[[sharedApplication stub] andReturnValue:@YES] canOpenURL:OCMOCK_ANY];

            });

            afterEach(^{
                [venmoRequestURL verify];
                [venmoRequestURL stopMocking];
            });

            beforeEach(^{
                [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusProduction)] btVenmo_status];
            });

            it(@"returns nil and calls delegate if successfully app switches", ^{
                handler.returnURLScheme = @"a-scheme";
                [[[client stub] andReturn:@"a-merchant-id"] merchantId];
                NSURL *url = [NSURL URLWithString:@"a-scheme://a-host"];
                [[[venmoRequestURL stub] andReturn:url] appSwitchURLForMerchantID:@"a-merchant-id" returnURLScheme:@"a-scheme" offline:NO];
                [[[sharedApplication expect] andReturnValue:@YES] openURL:url];

                [[delegate expect] appSwitcherWillSwitch:handler];

                NSError *error = [handler initiateAppSwitchWithClient:client delegate:delegate];
                expect(error).to.beNil();
            });

        });


    });

    describe(@"handleReturnURL:", ^{

        __block id appSwitchReturnURL;
        __block id paymentMethod;

        NSURL *returnURL = [NSURL URLWithString:@"scheme://host/x"];

        beforeEach(^{
            delegate = [OCMockObject mockForProtocol:@protocol(BTAppSwitchingDelegate)];
            handler.delegate = delegate;
            client = [OCMockObject mockForClass:[BTClient class]];
            handler.client = client;

            appSwitchReturnURL = [OCMockObject mockForClass:[BTVenmoAppSwitchReturnURL class]];
            [[[appSwitchReturnURL stub] andReturn:appSwitchReturnURL] alloc];
            __unused id _ = [[[appSwitchReturnURL stub] andReturn:appSwitchReturnURL] initWithURL:returnURL];

            paymentMethod = [OCMockObject mockForClass:[BTPaymentMethod class]];
            [[[paymentMethod stub] andReturn:@"a-nonce" ] nonce];

            [[[appSwitchReturnURL stub] andReturn:paymentMethod] paymentMethod];
        });

        afterEach(^{
            [appSwitchReturnURL verify];
            [appSwitchReturnURL stopMocking];
        });

        describe(@"with valid URL and with Venmo set to production", ^{

            beforeEach(^{
                [[[appSwitchReturnURL stub] andReturnValue:OCMOCK_VALUE(BTVenmoAppSwitchReturnURLStateSucceeded)] state];
                [[[client stub] andReturnValue:OCMOCK_VALUE(BTVenmoStatusProduction)] btVenmo_status];
            });

            it(@"performs fetchPaymentMethodWithNonce:success:failure:", ^{
                [[delegate expect] appSwitcherWillCreatePaymentMethod:handler];
                [[client expect] postAnalyticsEvent:@"ios.venmo.appswitch.handle.authorized"];
                [[client expect] fetchPaymentMethodWithNonce:@"a-nonce" success:OCMOCK_ANY failure:OCMOCK_ANY];

                // TODO - examine blocks passed to fetchPaymentMethodWithNonce
                // [[client expect] fetchPaymentMethodWithNonce:@"a-nonce" success:OCMOCK_ANY failure:OCMOCK_ANY];
                // [[delegate expect] appSwitcher:handler didCreatePaymentMethod:paymentMethod];

                [handler handleReturnURL:returnURL];
            });
        });
    });
});


SpecEnd
