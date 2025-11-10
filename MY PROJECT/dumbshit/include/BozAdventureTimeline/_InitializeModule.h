
#include <memory>
#include "CommonDeclarations.h"
#include "LavishScript.h"
    
#pragma region Module file includes
#include "OneStepDistressingTechnique.h"
#include "RiccawwsCommandos.h"
#include "RootsinCorruption.h"
#include "ScreechingwithSangHuuuScouts.h"
#include "SkirhasPreservingProwess.h"
#include "SleepySolutions.h"
#include "SlimyYetSatisfying.h"
#include "SplendorRecycling.h"
#include "SplendorSkyAerieDragonRunedRing.h"
#include "SplendorSkyAerieRepeatableTimeline.h"
#include "SplendorSkyAerieRunescribedEmerald.h"
#include "SplendorSkyAerieRunescribedOnyx.h"
#include "SplendorSkyAerieRunescribedOpal.h"
#include "SplendorSkyAerieRunescribedRingTimeline.h"
#include "SplendorSkyAerieRunescribedRuby.h"
#include "SplendorSkyAerieRunescribedSapphire.h"
#include "SplendorSkyAerieSideTimeline.h"
#include "StickySweetVengeance.h"
#include "StokingtheForge.h"
#include "StormsABrewin.h"
#include "StormyDefenses.h"
#include "TheFluttersandMuttersRiddle.h"
#include "TheHandsofFate.h"
#include "TheShockandSplinterRiddle.h"
#include "TheVeinsandFlakesRiddle.h"
#include "ToAether.h"
#include "ToZimara.h"
#include "VaashkaaniAlcazarCrescendo.h"
#include "WindBeneathTheirWings.h"
#include "ZakirRishRemoval.h"
#include "ZBRR.h"
#include "ZBSS.h"
#include "ZBV.h"
#include "ZimaraBreadthCipFeather.h"
#include "ZimaraBreadthCursedFeathers.h"
#include "ZimaraBreadthCursedFeathersTimeline.h"
#include "ZimaraBreadthDolFeather.h"
#include "ZimaraBreadthKurFeather.h"
#include "ZimaraBreadthNabFeather.h"
#include "ZimaraBreadthSideTimeline.h"
#include "ZimaraBreadthTefFeather.h"
#include "ZimaraBreadtNabFeather.h"
#include "ZimaraBreadtTefFeather.h"

#pragma endregion
    
#pragma region Forward Declarations
bool TLO_OneStepDistressingTechnique(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_RiccawwsCommandos(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_RootsinCorruption(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ScreechingwithSangHuuuScouts(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SkirhasPreservingProwess(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SleepySolutions(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SlimyYetSatisfying(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorRecycling(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieDragonRunedRing(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieRepeatableTimeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieRunescribedEmerald(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieRunescribedOnyx(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieRunescribedOpal(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieRunescribedRingTimeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieRunescribedRuby(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieRunescribedSapphire(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_SplendorSkyAerieSideTimeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_StickySweetVengeance(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_StokingtheForge(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_StormsABrewin(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_StormyDefenses(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheFluttersandMuttersRiddle(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheHandsofFate(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheShockandSplinterRiddle(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheVeinsandFlakesRiddle(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ToAether(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ToZimara(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_VaashkaaniAlcazarCrescendo(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_WindBeneathTheirWings(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZakirRishRemoval(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZBRR(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZBSS(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZBV(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthCipFeather(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthCursedFeathers(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthCursedFeathersTimeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthDolFeather(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthKurFeather(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthNabFeather(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthSideTimeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadthTefFeather(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadtNabFeather(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ZimaraBreadtTefFeather(int argc, char* argv[], LSTYPEVAR& dest);

#pragma endregion
        
class TLOHandler : public ITLOHandler
{
public:
	static std::shared_ptr<TLOHandler> Create()
	{
		std::shared_ptr<TLOHandler> instance(new TLOHandler(), [](TLOHandler* p)
			{ delete p; });
		TLOHandlerRegistry::RegisterHandler(instance);
		return instance;
	}
     
#pragma region Register TLO Function
    void RegisterTLOs(ISInterface* pISInterface) override
    {
        pISInterface->AddTopLevelObject("ONESTEPDISTRESSINGTECHNIQUE", TLO_OneStepDistressingTechnique);
        pISInterface->AddTopLevelObject("RICCAWWSCOMMANDOS", TLO_RiccawwsCommandos);
        pISInterface->AddTopLevelObject("ROOTSINCORRUPTION", TLO_RootsinCorruption);
        pISInterface->AddTopLevelObject("SCREECHINGWITHSANGHUUUSCOUTS", TLO_ScreechingwithSangHuuuScouts);
        pISInterface->AddTopLevelObject("SKIRHASPRESERVINGPROWESS", TLO_SkirhasPreservingProwess);
        pISInterface->AddTopLevelObject("SLEEPYSOLUTIONS", TLO_SleepySolutions);
        pISInterface->AddTopLevelObject("SLIMYYETSATISFYING", TLO_SlimyYetSatisfying);
        pISInterface->AddTopLevelObject("SPLENDORRECYCLING", TLO_SplendorRecycling);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIEDRAGONRUNEDRING", TLO_SplendorSkyAerieDragonRunedRing);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIEREPEATABLETIMELINE", TLO_SplendorSkyAerieRepeatableTimeline);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDEMERALD", TLO_SplendorSkyAerieRunescribedEmerald);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDONYX", TLO_SplendorSkyAerieRunescribedOnyx);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDOPAL", TLO_SplendorSkyAerieRunescribedOpal);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDRINGTIMELINE", TLO_SplendorSkyAerieRunescribedRingTimeline);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDRUBY", TLO_SplendorSkyAerieRunescribedRuby);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDSAPPHIRE", TLO_SplendorSkyAerieRunescribedSapphire);
        pISInterface->AddTopLevelObject("SPLENDORSKYAERIESIDETIMELINE", TLO_SplendorSkyAerieSideTimeline);
        pISInterface->AddTopLevelObject("STICKYSWEETVENGEANCE", TLO_StickySweetVengeance);
        pISInterface->AddTopLevelObject("STOKINGTHEFORGE", TLO_StokingtheForge);
        pISInterface->AddTopLevelObject("STORMSABREWIN", TLO_StormsABrewin);
        pISInterface->AddTopLevelObject("STORMYDEFENSES", TLO_StormyDefenses);
        pISInterface->AddTopLevelObject("THEFLUTTERSANDMUTTERSRIDDLE", TLO_TheFluttersandMuttersRiddle);
        pISInterface->AddTopLevelObject("THEHANDSOFFATE", TLO_TheHandsofFate);
        pISInterface->AddTopLevelObject("THESHOCKANDSPLINTERRIDDLE", TLO_TheShockandSplinterRiddle);
        pISInterface->AddTopLevelObject("THEVEINSANDFLAKESRIDDLE", TLO_TheVeinsandFlakesRiddle);
        pISInterface->AddTopLevelObject("TOAETHER", TLO_ToAether);
        pISInterface->AddTopLevelObject("TOZIMARA", TLO_ToZimara);
        pISInterface->AddTopLevelObject("VAASHKAANIALCAZARCRESCENDO", TLO_VaashkaaniAlcazarCrescendo);
        pISInterface->AddTopLevelObject("WINDBENEATHTHEIRWINGS", TLO_WindBeneathTheirWings);
        pISInterface->AddTopLevelObject("ZAKIRRISHREMOVAL", TLO_ZakirRishRemoval);
        pISInterface->AddTopLevelObject("ZBRR", TLO_ZBRR);
        pISInterface->AddTopLevelObject("ZBSS", TLO_ZBSS);
        pISInterface->AddTopLevelObject("ZBV", TLO_ZBV);
        pISInterface->AddTopLevelObject("ZIMARABREADTHCIPFEATHER", TLO_ZimaraBreadthCipFeather);
        pISInterface->AddTopLevelObject("ZIMARABREADTHCURSEDFEATHERS", TLO_ZimaraBreadthCursedFeathers);
        pISInterface->AddTopLevelObject("ZIMARABREADTHCURSEDFEATHERSTIMELINE", TLO_ZimaraBreadthCursedFeathersTimeline);
        pISInterface->AddTopLevelObject("ZIMARABREADTHDOLFEATHER", TLO_ZimaraBreadthDolFeather);
        pISInterface->AddTopLevelObject("ZIMARABREADTHKURFEATHER", TLO_ZimaraBreadthKurFeather);
        pISInterface->AddTopLevelObject("ZIMARABREADTHNABFEATHER", TLO_ZimaraBreadthNabFeather);
        pISInterface->AddTopLevelObject("ZIMARABREADTHSIDETIMELINE", TLO_ZimaraBreadthSideTimeline);
        pISInterface->AddTopLevelObject("ZIMARABREADTHTEFFEATHER", TLO_ZimaraBreadthTefFeather);
        pISInterface->AddTopLevelObject("ZIMARABREADTNABFEATHER", TLO_ZimaraBreadtNabFeather);
        pISInterface->AddTopLevelObject("ZIMARABREADTTEFFEATHER", TLO_ZimaraBreadtTefFeather);
        
    }
#pragma endregion
    
#pragma region Deregister TLO Function
    void DeregisterTLOs(ISInterface* pISInterface) override
    {
        pISInterface->RemoveTopLevelObject("ONESTEPDISTRESSINGTECHNIQUE");
        pISInterface->RemoveTopLevelObject("RICCAWWSCOMMANDOS");
        pISInterface->RemoveTopLevelObject("ROOTSINCORRUPTION");
        pISInterface->RemoveTopLevelObject("SCREECHINGWITHSANGHUUUSCOUTS");
        pISInterface->RemoveTopLevelObject("SKIRHASPRESERVINGPROWESS");
        pISInterface->RemoveTopLevelObject("SLEEPYSOLUTIONS");
        pISInterface->RemoveTopLevelObject("SLIMYYETSATISFYING");
        pISInterface->RemoveTopLevelObject("SPLENDORRECYCLING");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIEDRAGONRUNEDRING");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIEREPEATABLETIMELINE");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDEMERALD");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDONYX");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDOPAL");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDRINGTIMELINE");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDRUBY");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIERUNESCRIBEDSAPPHIRE");
        pISInterface->RemoveTopLevelObject("SPLENDORSKYAERIESIDETIMELINE");
        pISInterface->RemoveTopLevelObject("STICKYSWEETVENGEANCE");
        pISInterface->RemoveTopLevelObject("STOKINGTHEFORGE");
        pISInterface->RemoveTopLevelObject("STORMSABREWIN");
        pISInterface->RemoveTopLevelObject("STORMYDEFENSES");
        pISInterface->RemoveTopLevelObject("THEFLUTTERSANDMUTTERSRIDDLE");
        pISInterface->RemoveTopLevelObject("THEHANDSOFFATE");
        pISInterface->RemoveTopLevelObject("THESHOCKANDSPLINTERRIDDLE");
        pISInterface->RemoveTopLevelObject("THEVEINSANDFLAKESRIDDLE");
        pISInterface->RemoveTopLevelObject("TOAETHER");
        pISInterface->RemoveTopLevelObject("TOZIMARA");
        pISInterface->RemoveTopLevelObject("VAASHKAANIALCAZARCRESCENDO");
        pISInterface->RemoveTopLevelObject("WINDBENEATHTHEIRWINGS");
        pISInterface->RemoveTopLevelObject("ZAKIRRISHREMOVAL");
        pISInterface->RemoveTopLevelObject("ZBRR");
        pISInterface->RemoveTopLevelObject("ZBSS");
        pISInterface->RemoveTopLevelObject("ZBV");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHCIPFEATHER");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHCURSEDFEATHERS");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHCURSEDFEATHERSTIMELINE");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHDOLFEATHER");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHKURFEATHER");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHNABFEATHER");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHSIDETIMELINE");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTHTEFFEATHER");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTNABFEATHER");
        pISInterface->RemoveTopLevelObject("ZIMARABREADTTEFFEATHER");
        
    }
#pragma endregion
    
private:
    TLOHandler() = default;
    ~TLOHandler() override = default;
};
    
// Automatically create a new instance of the module
auto handlerInstance = TLOHandler::Create();
    
#pragma region TLO Functions

bool TLO_OneStepDistressingTechnique(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(OneStepDistressingTechnique, argc, argv, dest);
}


bool TLO_RiccawwsCommandos(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(RiccawwsCommandos, argc, argv, dest);
}


bool TLO_RootsinCorruption(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(RootsinCorruption, argc, argv, dest);
}


bool TLO_ScreechingwithSangHuuuScouts(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ScreechingwithSangHuuuScouts, argc, argv, dest);
}


bool TLO_SkirhasPreservingProwess(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SkirhasPreservingProwess, argc, argv, dest);
}


bool TLO_SleepySolutions(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SleepySolutions, argc, argv, dest);
}


bool TLO_SlimyYetSatisfying(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SlimyYetSatisfying, argc, argv, dest);
}


bool TLO_SplendorRecycling(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorRecycling, argc, argv, dest);
}


bool TLO_SplendorSkyAerieDragonRunedRing(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieDragonRunedRing, argc, argv, dest);
}


bool TLO_SplendorSkyAerieRepeatableTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieRepeatableTimeline, argc, argv, dest);
}


bool TLO_SplendorSkyAerieRunescribedEmerald(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieRunescribedEmerald, argc, argv, dest);
}


bool TLO_SplendorSkyAerieRunescribedOnyx(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieRunescribedOnyx, argc, argv, dest);
}


bool TLO_SplendorSkyAerieRunescribedOpal(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieRunescribedOpal, argc, argv, dest);
}


bool TLO_SplendorSkyAerieRunescribedRingTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieRunescribedRingTimeline, argc, argv, dest);
}


bool TLO_SplendorSkyAerieRunescribedRuby(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieRunescribedRuby, argc, argv, dest);
}


bool TLO_SplendorSkyAerieRunescribedSapphire(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieRunescribedSapphire, argc, argv, dest);
}


bool TLO_SplendorSkyAerieSideTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(SplendorSkyAerieSideTimeline, argc, argv, dest);
}


bool TLO_StickySweetVengeance(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(StickySweetVengeance, argc, argv, dest);
}


bool TLO_StokingtheForge(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(StokingtheForge, argc, argv, dest);
}


bool TLO_StormsABrewin(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(StormsABrewin, argc, argv, dest);
}


bool TLO_StormyDefenses(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(StormyDefenses, argc, argv, dest);
}


bool TLO_TheFluttersandMuttersRiddle(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheFluttersandMuttersRiddle, argc, argv, dest);
}


bool TLO_TheHandsofFate(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheHandsofFate, argc, argv, dest);
}


bool TLO_TheShockandSplinterRiddle(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheShockandSplinterRiddle, argc, argv, dest);
}


bool TLO_TheVeinsandFlakesRiddle(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheVeinsandFlakesRiddle, argc, argv, dest);
}


bool TLO_ToAether(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ToAether, argc, argv, dest);
}


bool TLO_ToZimara(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ToZimara, argc, argv, dest);
}


bool TLO_VaashkaaniAlcazarCrescendo(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(VaashkaaniAlcazarCrescendo, argc, argv, dest);
}


bool TLO_WindBeneathTheirWings(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(WindBeneathTheirWings, argc, argv, dest);
}


bool TLO_ZakirRishRemoval(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZakirRishRemoval, argc, argv, dest);
}


bool TLO_ZBRR(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZBRR, argc, argv, dest);
}


bool TLO_ZBSS(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZBSS, argc, argv, dest);
}


bool TLO_ZBV(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZBV, argc, argv, dest);
}


bool TLO_ZimaraBreadthCipFeather(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthCipFeather, argc, argv, dest);
}


bool TLO_ZimaraBreadthCursedFeathers(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthCursedFeathers, argc, argv, dest);
}


bool TLO_ZimaraBreadthCursedFeathersTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthCursedFeathersTimeline, argc, argv, dest);
}


bool TLO_ZimaraBreadthDolFeather(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthDolFeather, argc, argv, dest);
}


bool TLO_ZimaraBreadthKurFeather(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthKurFeather, argc, argv, dest);
}


bool TLO_ZimaraBreadthNabFeather(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthNabFeather, argc, argv, dest);
}


bool TLO_ZimaraBreadthSideTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthSideTimeline, argc, argv, dest);
}


bool TLO_ZimaraBreadthTefFeather(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadthTefFeather, argc, argv, dest);
}


bool TLO_ZimaraBreadtNabFeather(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadtNabFeather, argc, argv, dest);
}


bool TLO_ZimaraBreadtTefFeather(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ZimaraBreadtTefFeather, argc, argv, dest);
}


#pragma endregion    
