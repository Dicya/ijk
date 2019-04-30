//
//  KTVCaptureList.h
//  ktv
//
//  Created by Ke on 6/25/15.
//  Borrowed from http://holko.pl/2015/05/31/weakify-strongify/
//

#ifndef ktv_KTVCaptureList_h
#define ktv_KTVCaptureList_h

#define weakify(var) __weak typeof(var) KTVWeak_##var = var;

#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = KTVWeak_##var; \
_Pragma("clang diagnostic pop")

#endif
