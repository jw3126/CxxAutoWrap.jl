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

class StringContainer
{
public:
    StringContainer(char* s) {x = s;}
    char* getIt();
    void setIt(char* s);
private:
    char* x;


};

#endif
