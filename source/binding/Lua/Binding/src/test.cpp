#include <MaaFramework/MaaAPI.h>
#include <iostream>

int main()
{
    auto v = MaaVersion();
    std::cout<<v;
    return 0;
}