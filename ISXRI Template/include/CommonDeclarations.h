#ifndef COMMONDECLARATIONS_H
#define COMMONDECLARATIONS_H

#include <string>
#include "LSType.h"
#include "ISXDK.h"

#include <memory>
#include <vector>

template <size_t N>
bool CommonTLOFunction(const std::string (&array)[N], int argc, char *argv[], LSTYPEVAR &dest)
{
    if (argc > 1)
    {
        if (strcmp(argv[0], "3rtZdjv7") != 0)
        {
            return false;
        }

        int num = atoi(argv[1]);
        if (*argv[1] == '#')
        {
            dest.Int = N;
            dest.Type = pIntType;
            return true;
        }
        else if (num < static_cast<int>(N))
        {
            dest.ConstCharPtr = array[num].c_str();
            dest.Type = pStringType;
            return true;
        }
        else
        {
            printf("Array out of bounds\n");
            return false;
        }
    }
    else
    {
        printf("Usage: ${Variable[X]} or ${Variable[#]}, X=string value at element X in array, #=Number of elements in the array\n");
    }
    return false;
}

class ITLOHandler {
public:
    virtual ~ITLOHandler() = default;
    virtual void RegisterTLOs(ISInterface* pISInterface) = 0;
    virtual void DeregisterTLOs(ISInterface* pISInterface) = 0;
};


class TLOHandlerRegistry {
public:
    static void RegisterHandler(std::shared_ptr<ITLOHandler> handler) {
        GetHandlers().push_back(handler);
    }

    static void RegisterTLOs(ISInterface* pISInterface) {
        for (auto& handler : GetHandlers()) {
            handler->RegisterTLOs(pISInterface);
        }
    }

    static void DeregisterTLOs(ISInterface* pISInterface) {
        for (auto& handler : GetHandlers()) {
            handler->DeregisterTLOs(pISInterface);
        }
    }

private:
    static std::vector<std::shared_ptr<ITLOHandler>>& GetHandlers() {
        static std::vector<std::shared_ptr<ITLOHandler>> handlers;
        return handlers;
    }
};



#endif // COMMONDECLARATIONS_H