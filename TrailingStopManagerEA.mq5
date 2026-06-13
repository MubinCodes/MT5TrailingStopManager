//+------------------------------------------------------------------+
//| TrailingStopManagerEA.mq5                                        |
//| MetaTrader 5 Breakeven and Trailing Stop Manager EA              |
//| Author: MubinCodes                                               |
//| GitHub: https://github.com/MubinCodes                            |
//|                                                                  |
//| This EA manages stop-loss levels for existing positions.         |
//| It supports breakeven and trailing stop logic using either       |
//| fixed pip-based triggers or percentage-of-take-profit triggers.  |
//|                                                                  |
//| Disclaimer: This project is for educational and portfolio        |
//| demonstration purposes only. Trading involves risk.              |
//+------------------------------------------------------------------+


#property copyright "MubinCodes"
#property link      "https://github.com/MubinCodes"
#property version   "1.00"


#include <Trade/Trade.mqh>
CTrade trade; // Create a trade object


//trailing stop and sl
input string gap991= "-----------------------------------------------------" ; // -----------------------------------------------------
input string gap213= "-----------------------------------------------------" ; // Breakeven & Trailing stop Settings
input bool BreakEven = false;

enum BreakEvenType
      {
         Pip=0,        
         Percentage=1   //Percentage(%)
         
      };
      
input BreakEvenType BreakEvenMethod = Pip;

input double BreakEvenTriggerPip = 20;
input double BreakEvenTriggerPercentageAt = 50; //BreakEvenTriggerPercentageAt(%)

//bool goForBreakEven = false;
input string gap98= "--------------------------" ; // --------------------------


input bool TrailingStop = true;

input BreakEvenType TrailingStopMethod = Pip;

input double TrailingStopTriggerPip= 25; //Trailing Stop Loss Trigger Pip
input  double TrailingStopTriggerPercentageAt = 50; //TrailingStopTriggerPercentageAt(%)

input double TrailingStep = 10;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      BreakEvenAndTrailingStop();
  }
//+------------------------------------------------------------------+


//breakeven and trailing stop function

void BreakEvenAndTrailingStop()
{
    double pip= Point() * 10;
    
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), Digits());
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), Digits());
    
   if(TrailingStop == true || BreakEven == true)
   {
      double firstDistance;
      double currentDistance;
      
      double newSl;
      int slDiff;
      
      double takeProfitPip;
      double breakEvenRequiredPipFinal;
      double trailingStopRequiredPipFinal;
      
      
      for(int i=0; i<PositionsTotal(); i++)
      {
            ulong positionTicket = PositionGetTicket(i); // this is must
                 
            string positionSymbol = PositionGetString(POSITION_SYMBOL);
            ulong positionMagicNumber = PositionGetInteger(POSITION_MAGIC);
            
            double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double positionStopLoss = PositionGetDouble(POSITION_SL);
            double positionLotSize = PositionGetDouble(POSITION_VOLUME);
            double currentStopLossLevel = PositionGetDouble(POSITION_SL);
            double currentTakeProfitLevel = PositionGetDouble(POSITION_TP); 
            
            
            if(positionSymbol == Symbol())
            {
                if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) // buy
                {
                    firstDistance= (Bid - positionOpenPrice)/pip;
                    currentDistance= (Bid - positionStopLoss)/pip;
                    
                    newSl= (Bid- TrailingStep*pip);
                                      
                    takeProfitPip = (currentTakeProfitLevel - positionOpenPrice) / pip;
                    
                  
                  
                  //selecting method for breakEven----------------------
                  if(BreakEvenMethod == 0) //direct pip
                  {
                     breakEvenRequiredPipFinal = BreakEvenTriggerPip;
                  }
                  else if(BreakEvenMethod == 1) //TP percentage
                  {                                         
                     breakEvenRequiredPipFinal = ((takeProfitPip / 100) * BreakEvenTriggerPercentageAt);
                  }
                  
                  if(BreakEven == true)
                  {
                     //BreakEven
                     if(firstDistance>= breakEvenRequiredPipFinal && positionStopLoss < positionOpenPrice)
                     {
                        trade.PositionModify(positionTicket, positionOpenPrice, currentTakeProfitLevel);
                                               
                     }
                  }
                  
                  
                  
                  
                  
                  //---------------------trailing stop for buy-----------------------------------
                                    
                  //selecting method for Trailing
                  if(TrailingStopMethod == 0) //direct pip
                  {                                          
                     trailingStopRequiredPipFinal = TrailingStopTriggerPip;
                  }
                  else if(TrailingStopMethod == 1) //TP percentage
                  {                                          
                     trailingStopRequiredPipFinal = ((takeProfitPip / 100) * TrailingStopTriggerPercentageAt);
                  }
                  
                  
                  if(TrailingStop == true)
                  {
                     //trailing
                     if(firstDistance>= trailingStopRequiredPipFinal && currentDistance>= TrailingStep && newSl > positionStopLoss)
                     {
                          trade.PositionModify(positionTicket, newSl, currentTakeProfitLevel);        
                     }
                  }
                  
                  
                }
                else if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) // Sell
                {
                    firstDistance= (positionOpenPrice - Ask)/pip;
                    currentDistance= (positionStopLoss - Ask)/pip;
                    
                    newSl= (Ask+ TrailingStep*pip);
                    slDiff= (positionStopLoss-newSl)/pip;
                  
                    takeProfitPip = (positionOpenPrice - currentTakeProfitLevel) / pip;
                    
                    
                    
                    //breakeven---------------------
                    //selecting method for breakEven
                     if(BreakEvenMethod == 0) //direct pip
                     {                                             
                        breakEvenRequiredPipFinal = BreakEvenTriggerPip;
                     }
                     else if(BreakEvenMethod == 1) //TP percentage
                     {                       
                        breakEvenRequiredPipFinal = ((takeProfitPip / 100) * BreakEvenTriggerPercentageAt);
                     }
                     
                     
                     if(BreakEven == true)
                     {
                         //BreakEven
                        if(firstDistance>= breakEvenRequiredPipFinal && positionStopLoss > positionOpenPrice)
                        {
                           trade.PositionModify(positionTicket, positionOpenPrice, currentTakeProfitLevel);                         
                          
                        }
                     }
                     
                     
                     
                     //trailing stop sell----------------------------------
                     //selecting method for Trailing
                     if(TrailingStopMethod == 0) //direct pip
                     {
                                             
                        trailingStopRequiredPipFinal = TrailingStopTriggerPip;
                     }
                     else if(TrailingStopMethod == 1) //TP percentage
                     {
                                             
                        trailingStopRequiredPipFinal = ((takeProfitPip / 100) * TrailingStopTriggerPercentageAt);
                     }
                     
                     
                     if(TrailingStop == true)
                     {
                        if(firstDistance>= trailingStopRequiredPipFinal && currentDistance>= TrailingStep && slDiff>= 1 && newSl < positionStopLoss)
                        {
                            trade.PositionModify(positionTicket, newSl, currentTakeProfitLevel);                                                         
                        }
                     }
                    
                }
            }
      }
   }    
}
