#ifndef INTCONTAINER_LIBRARY_H
#define INTCONTAINER_LIBRARY_H

class IntContainer
{
public:
    IntContainer(int i) {
        x = i;
    }
    void setIt(int i);
    int getIt();
private:
    int x;
};


#endif