#include "library.h"



int IntContainer::getIt() {
    return x;
}

void IntContainer::setIt(int i) {
    x = i;
}

// bool IntContainer::operator==(IntContainer other) {
//     int y = other.getIt();
//     bool ret = (x == y);
//     std::cout << "x = " << x << "y = "  << y << ret <<std::endl;
//
//     return ret;
// }

char* StringContainer::getIt() {
    return x;
}

void StringContainer::setIt(char* i) {
    x = i;
}
