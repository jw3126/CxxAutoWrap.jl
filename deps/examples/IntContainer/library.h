#ifndef INTCONTAINER_LIBRARY_H
#define INTCONTAINER_LIBRARY_H

#include <iostream>

class IntContainer
{
public:
    IntContainer(int i) {
        x = i;
    }
    void setIt(int i);
    int getIt();
    ~IntContainer() { std::cout << "destructor of IntContainer called successfully" << std::endl; }
private:
    int x;
};


#endif