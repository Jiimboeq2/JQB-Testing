
#include <memory>
#include "CommonDeclarations.h"
#include "LavishScript.h"
    
#pragma region Module file includes
#include "BeginnerBotanyAntonicanFlora.h"
#include "BeginnerBotanyButcherblockMountains.h"
#include "BeginnerBotanyCommonlandsPlants.h"
#include "BeginnerBotanyDarklightDiversity.h"
#include "BeginnerBotanyFrostfangFlora.h"
#include "BeginnerBotanyGreaterFaydark.h"
#include "BeginnerBotanyNektulosForest.h"
#include "BeginnerBotanyThunderingSteppes.h"
#include "BeginnerBotanyTimorousDeep.h"
#include "ThenewTravelsofYunZiAntonicaorBust.h"
#include "ThenewTravelsofYunZiCommonlandsUncommonHeart.h"
#include "ThenewTravelsofYunZiDefrostingEverfrost.h"
#include "ThenewTravelsofYunZiDisenchantingtheEnchanted.h"
#include "ThenewTravelsofYunZiFeerrottNotIShallFindYou.h"
#include "ThenewTravelsofYunZiHavingFunStormingLavastorm.h"
#include "ThenewTravelsofYunZiRunNektulosForestRun.h"
#include "ThenewTravelsofYunZiThunderingSteppesBySteppes.h"
#include "ThenewTravelsofYunZiTimeline.h"
#include "ThenewTravelsofYunZiToZekWithIt.h"
#include "TheTravelsofYunZiAnAltarNateMalice.h"
#include "TheTravelsofYunZiAnEternityWithoutYou.h"
#include "TheTravelsofYunZiAnOasisForYourThoughts.h"
#include "TheTravelsofYunZiEchoesofthePast.h"
#include "TheTravelsofYunZiIcetoSeeVelious.h"
#include "TheTravelsofYunZiInaKingdomFarAway.h"
#include "TheTravelsofYunZiINeedtoSeeMoorsPlaces.h"
#include "TheTravelsofYunZiKunarkorBust.h"
#include "TheTravelsofYunZiTearsforFears.h"
#include "TheTravelsofYunZiTimeline.h"
#include "TravelersFeastButcherblockPumpkinBread.h"
#include "TravelersFeastColdwindClamChowder.h"
#include "TravelersFeastDarklightBeetleOmelets.h"
#include "TravelersFeastDervishSquashCurry.h"
#include "TravelersFeastKylongBeanCasserole.h"
#include "TravelersFeastMaraMandaikonKakiage.h"
#include "TravelersFeastOthmirPepperPasta.h"
#include "TravelersFeastRivervaleRatatouille.h"
#include "TravelersFeastSkyCake.h"
#include "TravelersHolidaysDeadlyNights.h"
#include "TravelersHolidaysEvokingLove.h"
#include "TravelersHolidaysGearsandGadgets.h"
#include "TravelersHolidaysGettingaFeelForFrostfell.h"
#include "TravelersHolidaysMorethanBeer.h"
#include "TravelersHolidaysOceansfortheOceanless.h"
#include "TravelersHolidaysTheMeaningofMischief.h"
#include "TravelersHolidaysUnderaBurningSky.h"
#include "TravelersHolidaysWeNeedaHero.h"
#include "TravelersKunarkCatalogAngryAngryAngry.h"
#include "TravelersKunarkCatalogAroundtheLanding.h"
#include "TravelersKunarkCatalogCentralKylong.h"
#include "TravelersKunarkCatalogDeeperintoKylong.h"
#include "TravelersKunarkCatalogFocusingonFens.h"
#include "TravelersKunarkCatalogKillersinKunzar.h"
#include "TravelersKunarkCatalogNotthePanda.h"
#include "TravelersKunarkCatalogScoutingSkyfire.h"
#include "TravelersKunarkCatalogStillnotaPanda.h"
#include "YetmoreTravelsofYunZiAlteringtheAltar.h"
#include "YetmoreTravelsofYunZiDestinedforDestiny.h"
#include "YetmoreTravelsofYunZiECHOECHoEChoEchoecho.h"
#include "YetmoreTravelsofYunZiEternallyEternity.h"
#include "YetmoreTravelsofYunZiMoreMoors.h"
#include "YetmoreTravelsofYunZiOnceAgainintheDesert.h"
#include "YetmoreTravelsofYunZiReturningtoTears.h"
#include "YetmoreTravelsofYunZiRisingtotheOccasion.h"
#include "YetmoreTravelsofYunZiSkiestheLimit.h"
#include "Yunzi2017Timeline.h"
#include "Yunzi2018Timeline.h"
#include "Yunzi2019Timeline.h"
#include "Yunzi2020Timeline.h"
#include "Yunzi2021Timeline.h"
#include "Yunzi2022Timeline.h"
#include "Yunzi2023Timeline.h"
#include "YunziTimeline.h"

#pragma endregion
    
#pragma region Forward Declarations
bool TLO_BeginnerBotanyAntonicanFlora(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyButcherblockMountains(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyCommonlandsPlants(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyDarklightDiversity(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyFrostfangFlora(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyGreaterFaydark(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyNektulosForest(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyThunderingSteppes(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_BeginnerBotanyTimorousDeep(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiAntonicaorBust(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiCommonlandsUncommonHeart(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiDefrostingEverfrost(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiDisenchantingtheEnchanted(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiFeerrottNotIShallFindYou(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiHavingFunStormingLavastorm(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiRunNektulosForestRun(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiThunderingSteppesBySteppes(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiTimeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_ThenewTravelsofYunZiToZekWithIt(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiAnAltarNateMalice(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiAnEternityWithoutYou(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiAnOasisForYourThoughts(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiEchoesofthePast(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiIcetoSeeVelious(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiInaKingdomFarAway(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiINeedtoSeeMoorsPlaces(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiKunarkorBust(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiTearsforFears(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TheTravelsofYunZiTimeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastButcherblockPumpkinBread(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastColdwindClamChowder(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastDarklightBeetleOmelets(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastDervishSquashCurry(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastKylongBeanCasserole(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastMaraMandaikonKakiage(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastOthmirPepperPasta(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastRivervaleRatatouille(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersFeastSkyCake(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysDeadlyNights(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysEvokingLove(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysGearsandGadgets(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysGettingaFeelForFrostfell(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysMorethanBeer(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysOceansfortheOceanless(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysTheMeaningofMischief(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysUnderaBurningSky(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersHolidaysWeNeedaHero(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogAngryAngryAngry(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogAroundtheLanding(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogCentralKylong(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogDeeperintoKylong(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogFocusingonFens(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogKillersinKunzar(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogNotthePanda(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogScoutingSkyfire(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_TravelersKunarkCatalogStillnotaPanda(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiAlteringtheAltar(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiDestinedforDestiny(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiECHOECHoEChoEchoecho(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiEternallyEternity(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiMoreMoors(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiOnceAgainintheDesert(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiReturningtoTears(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiRisingtotheOccasion(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YetmoreTravelsofYunZiSkiestheLimit(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_Yunzi2017Timeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_Yunzi2018Timeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_Yunzi2019Timeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_Yunzi2020Timeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_Yunzi2021Timeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_Yunzi2022Timeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_Yunzi2023Timeline(int argc, char* argv[], LSTYPEVAR& dest);
bool TLO_YunziTimeline(int argc, char* argv[], LSTYPEVAR& dest);

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
        pISInterface->AddTopLevelObject("BEGINNERBOTANYANTONICANFLORA", TLO_BeginnerBotanyAntonicanFlora);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYBUTCHERBLOCKMOUNTAINS", TLO_BeginnerBotanyButcherblockMountains);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYCOMMONLANDSPLANTS", TLO_BeginnerBotanyCommonlandsPlants);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYDARKLIGHTDIVERSITY", TLO_BeginnerBotanyDarklightDiversity);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYFROSTFANGFLORA", TLO_BeginnerBotanyFrostfangFlora);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYGREATERFAYDARK", TLO_BeginnerBotanyGreaterFaydark);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYNEKTULOSFOREST", TLO_BeginnerBotanyNektulosForest);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYTHUNDERINGSTEPPES", TLO_BeginnerBotanyThunderingSteppes);
        pISInterface->AddTopLevelObject("BEGINNERBOTANYTIMOROUSDEEP", TLO_BeginnerBotanyTimorousDeep);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZIANTONICAORBUST", TLO_ThenewTravelsofYunZiAntonicaorBust);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZICOMMONLANDSUNCOMMONHEART", TLO_ThenewTravelsofYunZiCommonlandsUncommonHeart);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZIDEFROSTINGEVERFROST", TLO_ThenewTravelsofYunZiDefrostingEverfrost);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZIDISENCHANTINGTHEENCHANTED", TLO_ThenewTravelsofYunZiDisenchantingtheEnchanted);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZIFEERROTTNOTISHALLFINDYOU", TLO_ThenewTravelsofYunZiFeerrottNotIShallFindYou);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZIHAVINGFUNSTORMINGLAVASTORM", TLO_ThenewTravelsofYunZiHavingFunStormingLavastorm);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZIRUNNEKTULOSFORESTRUN", TLO_ThenewTravelsofYunZiRunNektulosForestRun);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZITHUNDERINGSTEPPESBYSTEPPES", TLO_ThenewTravelsofYunZiThunderingSteppesBySteppes);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZITIMELINE", TLO_ThenewTravelsofYunZiTimeline);
        pISInterface->AddTopLevelObject("THENEWTRAVELSOFYUNZITOZEKWITHIT", TLO_ThenewTravelsofYunZiToZekWithIt);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIANALTARNATEMALICE", TLO_TheTravelsofYunZiAnAltarNateMalice);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIANETERNITYWITHOUTYOU", TLO_TheTravelsofYunZiAnEternityWithoutYou);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIANOASISFORYOURTHOUGHTS", TLO_TheTravelsofYunZiAnOasisForYourThoughts);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIECHOESOFTHEPAST", TLO_TheTravelsofYunZiEchoesofthePast);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIICETOSEEVELIOUS", TLO_TheTravelsofYunZiIcetoSeeVelious);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIINAKINGDOMFARAWAY", TLO_TheTravelsofYunZiInaKingdomFarAway);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIINEEDTOSEEMOORSPLACES", TLO_TheTravelsofYunZiINeedtoSeeMoorsPlaces);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZIKUNARKORBUST", TLO_TheTravelsofYunZiKunarkorBust);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZITEARSFORFEARS", TLO_TheTravelsofYunZiTearsforFears);
        pISInterface->AddTopLevelObject("THETRAVELSOFYUNZITIMELINE", TLO_TheTravelsofYunZiTimeline);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTBUTCHERBLOCKPUMPKINBREAD", TLO_TravelersFeastButcherblockPumpkinBread);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTCOLDWINDCLAMCHOWDER", TLO_TravelersFeastColdwindClamChowder);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTDARKLIGHTBEETLEOMELETS", TLO_TravelersFeastDarklightBeetleOmelets);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTDERVISHSQUASHCURRY", TLO_TravelersFeastDervishSquashCurry);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTKYLONGBEANCASSEROLE", TLO_TravelersFeastKylongBeanCasserole);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTMARAMANDAIKONKAKIAGE", TLO_TravelersFeastMaraMandaikonKakiage);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTOTHMIRPEPPERPASTA", TLO_TravelersFeastOthmirPepperPasta);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTRIVERVALERATATOUILLE", TLO_TravelersFeastRivervaleRatatouille);
        pISInterface->AddTopLevelObject("TRAVELERSFEASTSKYCAKE", TLO_TravelersFeastSkyCake);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSDEADLYNIGHTS", TLO_TravelersHolidaysDeadlyNights);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSEVOKINGLOVE", TLO_TravelersHolidaysEvokingLove);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSGEARSANDGADGETS", TLO_TravelersHolidaysGearsandGadgets);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSGETTINGAFEELFORFROSTFELL", TLO_TravelersHolidaysGettingaFeelForFrostfell);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSMORETHANBEER", TLO_TravelersHolidaysMorethanBeer);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSOCEANSFORTHEOCEANLESS", TLO_TravelersHolidaysOceansfortheOceanless);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSTHEMEANINGOFMISCHIEF", TLO_TravelersHolidaysTheMeaningofMischief);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSUNDERABURNINGSKY", TLO_TravelersHolidaysUnderaBurningSky);
        pISInterface->AddTopLevelObject("TRAVELERSHOLIDAYSWENEEDAHERO", TLO_TravelersHolidaysWeNeedaHero);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGANGRYANGRYANGRY", TLO_TravelersKunarkCatalogAngryAngryAngry);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGAROUNDTHELANDING", TLO_TravelersKunarkCatalogAroundtheLanding);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGCENTRALKYLONG", TLO_TravelersKunarkCatalogCentralKylong);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGDEEPERINTOKYLONG", TLO_TravelersKunarkCatalogDeeperintoKylong);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGFOCUSINGONFENS", TLO_TravelersKunarkCatalogFocusingonFens);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGKILLERSINKUNZAR", TLO_TravelersKunarkCatalogKillersinKunzar);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGNOTTHEPANDA", TLO_TravelersKunarkCatalogNotthePanda);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGSCOUTINGSKYFIRE", TLO_TravelersKunarkCatalogScoutingSkyfire);
        pISInterface->AddTopLevelObject("TRAVELERSKUNARKCATALOGSTILLNOTAPANDA", TLO_TravelersKunarkCatalogStillnotaPanda);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIALTERINGTHEALTAR", TLO_YetmoreTravelsofYunZiAlteringtheAltar);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIDESTINEDFORDESTINY", TLO_YetmoreTravelsofYunZiDestinedforDestiny);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIECHOECHOECHOECHOECHO", TLO_YetmoreTravelsofYunZiECHOECHoEChoEchoecho);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIETERNALLYETERNITY", TLO_YetmoreTravelsofYunZiEternallyEternity);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIMOREMOORS", TLO_YetmoreTravelsofYunZiMoreMoors);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIONCEAGAININTHEDESERT", TLO_YetmoreTravelsofYunZiOnceAgainintheDesert);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIRETURNINGTOTEARS", TLO_YetmoreTravelsofYunZiReturningtoTears);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZIRISINGTOTHEOCCASION", TLO_YetmoreTravelsofYunZiRisingtotheOccasion);
        pISInterface->AddTopLevelObject("YETMORETRAVELSOFYUNZISKIESTHELIMIT", TLO_YetmoreTravelsofYunZiSkiestheLimit);
        pISInterface->AddTopLevelObject("YUNZI2017TIMELINE", TLO_Yunzi2017Timeline);
        pISInterface->AddTopLevelObject("YUNZI2018TIMELINE", TLO_Yunzi2018Timeline);
        pISInterface->AddTopLevelObject("YUNZI2019TIMELINE", TLO_Yunzi2019Timeline);
        pISInterface->AddTopLevelObject("YUNZI2020TIMELINE", TLO_Yunzi2020Timeline);
        pISInterface->AddTopLevelObject("YUNZI2021TIMELINE", TLO_Yunzi2021Timeline);
        pISInterface->AddTopLevelObject("YUNZI2022TIMELINE", TLO_Yunzi2022Timeline);
        pISInterface->AddTopLevelObject("YUNZI2023TIMELINE", TLO_Yunzi2023Timeline);
        pISInterface->AddTopLevelObject("YUNZITIMELINE", TLO_YunziTimeline);
        
    }
#pragma endregion
    
#pragma region Deregister TLO Function
    void DeregisterTLOs(ISInterface* pISInterface) override
    {
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYANTONICANFLORA");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYBUTCHERBLOCKMOUNTAINS");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYCOMMONLANDSPLANTS");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYDARKLIGHTDIVERSITY");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYFROSTFANGFLORA");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYGREATERFAYDARK");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYNEKTULOSFOREST");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYTHUNDERINGSTEPPES");
        pISInterface->RemoveTopLevelObject("BEGINNERBOTANYTIMOROUSDEEP");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZIANTONICAORBUST");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZICOMMONLANDSUNCOMMONHEART");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZIDEFROSTINGEVERFROST");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZIDISENCHANTINGTHEENCHANTED");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZIFEERROTTNOTISHALLFINDYOU");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZIHAVINGFUNSTORMINGLAVASTORM");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZIRUNNEKTULOSFORESTRUN");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZITHUNDERINGSTEPPESBYSTEPPES");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZITIMELINE");
        pISInterface->RemoveTopLevelObject("THENEWTRAVELSOFYUNZITOZEKWITHIT");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIANALTARNATEMALICE");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIANETERNITYWITHOUTYOU");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIANOASISFORYOURTHOUGHTS");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIECHOESOFTHEPAST");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIICETOSEEVELIOUS");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIINAKINGDOMFARAWAY");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIINEEDTOSEEMOORSPLACES");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZIKUNARKORBUST");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZITEARSFORFEARS");
        pISInterface->RemoveTopLevelObject("THETRAVELSOFYUNZITIMELINE");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTBUTCHERBLOCKPUMPKINBREAD");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTCOLDWINDCLAMCHOWDER");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTDARKLIGHTBEETLEOMELETS");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTDERVISHSQUASHCURRY");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTKYLONGBEANCASSEROLE");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTMARAMANDAIKONKAKIAGE");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTOTHMIRPEPPERPASTA");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTRIVERVALERATATOUILLE");
        pISInterface->RemoveTopLevelObject("TRAVELERSFEASTSKYCAKE");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSDEADLYNIGHTS");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSEVOKINGLOVE");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSGEARSANDGADGETS");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSGETTINGAFEELFORFROSTFELL");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSMORETHANBEER");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSOCEANSFORTHEOCEANLESS");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSTHEMEANINGOFMISCHIEF");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSUNDERABURNINGSKY");
        pISInterface->RemoveTopLevelObject("TRAVELERSHOLIDAYSWENEEDAHERO");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGANGRYANGRYANGRY");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGAROUNDTHELANDING");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGCENTRALKYLONG");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGDEEPERINTOKYLONG");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGFOCUSINGONFENS");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGKILLERSINKUNZAR");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGNOTTHEPANDA");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGSCOUTINGSKYFIRE");
        pISInterface->RemoveTopLevelObject("TRAVELERSKUNARKCATALOGSTILLNOTAPANDA");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIALTERINGTHEALTAR");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIDESTINEDFORDESTINY");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIECHOECHOECHOECHOECHO");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIETERNALLYETERNITY");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIMOREMOORS");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIONCEAGAININTHEDESERT");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIRETURNINGTOTEARS");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZIRISINGTOTHEOCCASION");
        pISInterface->RemoveTopLevelObject("YETMORETRAVELSOFYUNZISKIESTHELIMIT");
        pISInterface->RemoveTopLevelObject("YUNZI2017TIMELINE");
        pISInterface->RemoveTopLevelObject("YUNZI2018TIMELINE");
        pISInterface->RemoveTopLevelObject("YUNZI2019TIMELINE");
        pISInterface->RemoveTopLevelObject("YUNZI2020TIMELINE");
        pISInterface->RemoveTopLevelObject("YUNZI2021TIMELINE");
        pISInterface->RemoveTopLevelObject("YUNZI2022TIMELINE");
        pISInterface->RemoveTopLevelObject("YUNZI2023TIMELINE");
        pISInterface->RemoveTopLevelObject("YUNZITIMELINE");
        
    }
#pragma endregion
    
private:
    TLOHandler() = default;
    ~TLOHandler() override = default;
};
    
// Automatically create a new instance of the module
auto handlerInstance = TLOHandler::Create();
    
#pragma region TLO Functions

bool TLO_BeginnerBotanyAntonicanFlora(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyAntonicanFlora, argc, argv, dest);
}


bool TLO_BeginnerBotanyButcherblockMountains(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyButcherblockMountains, argc, argv, dest);
}


bool TLO_BeginnerBotanyCommonlandsPlants(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyCommonlandsPlants, argc, argv, dest);
}


bool TLO_BeginnerBotanyDarklightDiversity(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyDarklightDiversity, argc, argv, dest);
}


bool TLO_BeginnerBotanyFrostfangFlora(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyFrostfangFlora, argc, argv, dest);
}


bool TLO_BeginnerBotanyGreaterFaydark(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyGreaterFaydark, argc, argv, dest);
}


bool TLO_BeginnerBotanyNektulosForest(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyNektulosForest, argc, argv, dest);
}


bool TLO_BeginnerBotanyThunderingSteppes(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyThunderingSteppes, argc, argv, dest);
}


bool TLO_BeginnerBotanyTimorousDeep(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(BeginnerBotanyTimorousDeep, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiAntonicaorBust(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiAntonicaorBust, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiCommonlandsUncommonHeart(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiCommonlandsUncommonHeart, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiDefrostingEverfrost(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiDefrostingEverfrost, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiDisenchantingtheEnchanted(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiDisenchantingtheEnchanted, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiFeerrottNotIShallFindYou(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiFeerrottNotIShallFindYou, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiHavingFunStormingLavastorm(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiHavingFunStormingLavastorm, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiRunNektulosForestRun(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiRunNektulosForestRun, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiThunderingSteppesBySteppes(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiThunderingSteppesBySteppes, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiTimeline, argc, argv, dest);
}


bool TLO_ThenewTravelsofYunZiToZekWithIt(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(ThenewTravelsofYunZiToZekWithIt, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiAnAltarNateMalice(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiAnAltarNateMalice, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiAnEternityWithoutYou(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiAnEternityWithoutYou, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiAnOasisForYourThoughts(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiAnOasisForYourThoughts, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiEchoesofthePast(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiEchoesofthePast, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiIcetoSeeVelious(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiIcetoSeeVelious, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiInaKingdomFarAway(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiInaKingdomFarAway, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiINeedtoSeeMoorsPlaces(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiINeedtoSeeMoorsPlaces, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiKunarkorBust(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiKunarkorBust, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiTearsforFears(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiTearsforFears, argc, argv, dest);
}


bool TLO_TheTravelsofYunZiTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TheTravelsofYunZiTimeline, argc, argv, dest);
}


bool TLO_TravelersFeastButcherblockPumpkinBread(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastButcherblockPumpkinBread, argc, argv, dest);
}


bool TLO_TravelersFeastColdwindClamChowder(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastColdwindClamChowder, argc, argv, dest);
}


bool TLO_TravelersFeastDarklightBeetleOmelets(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastDarklightBeetleOmelets, argc, argv, dest);
}


bool TLO_TravelersFeastDervishSquashCurry(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastDervishSquashCurry, argc, argv, dest);
}


bool TLO_TravelersFeastKylongBeanCasserole(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastKylongBeanCasserole, argc, argv, dest);
}


bool TLO_TravelersFeastMaraMandaikonKakiage(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastMaraMandaikonKakiage, argc, argv, dest);
}


bool TLO_TravelersFeastOthmirPepperPasta(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastOthmirPepperPasta, argc, argv, dest);
}


bool TLO_TravelersFeastRivervaleRatatouille(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastRivervaleRatatouille, argc, argv, dest);
}


bool TLO_TravelersFeastSkyCake(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersFeastSkyCake, argc, argv, dest);
}


bool TLO_TravelersHolidaysDeadlyNights(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysDeadlyNights, argc, argv, dest);
}


bool TLO_TravelersHolidaysEvokingLove(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysEvokingLove, argc, argv, dest);
}


bool TLO_TravelersHolidaysGearsandGadgets(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysGearsandGadgets, argc, argv, dest);
}


bool TLO_TravelersHolidaysGettingaFeelForFrostfell(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysGettingaFeelForFrostfell, argc, argv, dest);
}


bool TLO_TravelersHolidaysMorethanBeer(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysMorethanBeer, argc, argv, dest);
}


bool TLO_TravelersHolidaysOceansfortheOceanless(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysOceansfortheOceanless, argc, argv, dest);
}


bool TLO_TravelersHolidaysTheMeaningofMischief(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysTheMeaningofMischief, argc, argv, dest);
}


bool TLO_TravelersHolidaysUnderaBurningSky(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysUnderaBurningSky, argc, argv, dest);
}


bool TLO_TravelersHolidaysWeNeedaHero(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersHolidaysWeNeedaHero, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogAngryAngryAngry(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogAngryAngryAngry, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogAroundtheLanding(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogAroundtheLanding, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogCentralKylong(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogCentralKylong, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogDeeperintoKylong(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogDeeperintoKylong, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogFocusingonFens(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogFocusingonFens, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogKillersinKunzar(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogKillersinKunzar, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogNotthePanda(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogNotthePanda, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogScoutingSkyfire(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogScoutingSkyfire, argc, argv, dest);
}


bool TLO_TravelersKunarkCatalogStillnotaPanda(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(TravelersKunarkCatalogStillnotaPanda, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiAlteringtheAltar(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiAlteringtheAltar, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiDestinedforDestiny(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiDestinedforDestiny, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiECHOECHoEChoEchoecho(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiECHOECHoEChoEchoecho, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiEternallyEternity(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiEternallyEternity, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiMoreMoors(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiMoreMoors, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiOnceAgainintheDesert(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiOnceAgainintheDesert, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiReturningtoTears(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiReturningtoTears, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiRisingtotheOccasion(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiRisingtotheOccasion, argc, argv, dest);
}


bool TLO_YetmoreTravelsofYunZiSkiestheLimit(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YetmoreTravelsofYunZiSkiestheLimit, argc, argv, dest);
}


bool TLO_Yunzi2017Timeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(Yunzi2017Timeline, argc, argv, dest);
}


bool TLO_Yunzi2018Timeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(Yunzi2018Timeline, argc, argv, dest);
}


bool TLO_Yunzi2019Timeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(Yunzi2019Timeline, argc, argv, dest);
}


bool TLO_Yunzi2020Timeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(Yunzi2020Timeline, argc, argv, dest);
}


bool TLO_Yunzi2021Timeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(Yunzi2021Timeline, argc, argv, dest);
}


bool TLO_Yunzi2022Timeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(Yunzi2022Timeline, argc, argv, dest);
}


bool TLO_Yunzi2023Timeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(Yunzi2023Timeline, argc, argv, dest);
}


bool TLO_YunziTimeline(int argc, char* argv[], LSTYPEVAR& dest)
{
    return CommonTLOFunction(YunziTimeline, argc, argv, dest);
}


#pragma endregion    
