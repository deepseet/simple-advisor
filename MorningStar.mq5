//+------------------------------------------------------------------+
//|                                                  MorningStar.mq5 |
//|                                     Copyright 2024, Restack Tech |
//|                                         https://www.restack.tech |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Restack Tech"
#property link      "https://www.restack.tech"
#property version   "1.00"
#property strict

#property script_show_inputs

//+------------------------------------------------------------------+
//| Input & Global Variables
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Input & Global Variables                                         |
//+------------------------------------------------------------------+
sinput group                              "EA GENERAL SETTINGS"
input ulong                               MagicNumber             = 101;
input bool                                UseFillingPolicy        = false;
input ENUM_ORDER_TYPE_FILLING             FillingPolicy           = ORDER_FILLING_FOK;

sinput group                              "MONEY MANAGEMENT"
input double                              FixedVolume             = 0.01;

double gDailyHigh = 0.0;
double gDailyLow = DBL_MAX;
datetime gLastResetTime = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   gDailyHigh = 0.0;
   gDailyLow = DBL_MAX;
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Print("Advisor removed");
}


void OnTick() {

   datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   MqlDateTime mqlTime;
   TimeToStruct(currentTime, mqlTime);

   if (mqlTime.hour == 7 && gLastResetTime != currentTime) {
      gLastResetTime = currentTime;  // 마지막 리셋 시간 업데이트
      gDailyHigh = 0.0;
      gDailyLow = DBL_MAX;
   }

// 7시부터 8시 사이 5분 간격으로 고저가 업데이트
   if (mqlTime.hour >= 7 && mqlTime.hour < 8) {
      double currentHigh = High(0);
      double currentLow = Low(0);
      if (currentHigh > gDailyHigh) gDailyHigh = currentHigh;
      if (currentLow < gDailyLow) gDailyLow = currentLow;
   }

// 8시 10분에 매매 신호 체크
   if (mqlTime.hour == 8 && mqlTime.min == 10) {
      Print(mqlTime.hour + ", " + mqlTime.min);
      double openPrice = Open(0);
      string signal = EntrySignal(gDailyHigh, gDailyLow, openPrice);
      if (signal != "") {
         // 매매 로직 실행
         Print("Open Trades!");
         ulong ticket = OpenTrades(signal, MagicNumber, FixedVolume, UseFillingPolicy, FillingPolicy);
      }
   }

   if (mqlTime.hour == 8 && mqlTime.min == 30) {
      Print("Close Trades!");
      CloseAllTrades(MagicNumber, UseFillingPolicy, FillingPolicy);
   }

//   if (glLastBarTime != currentBarTime) {
//      Print("New Bar Arrived");
//
//      // New bar has arrived
//      glLastBarTime = currentBarTime;
//
//      // Get the previous and current high and low
//      double previousHigh = High(1);
//      double previousLow = Low(1);
//
//      // Normalize prices to tick size
//      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
//      previousHigh = NormalizeD(previousHigh,  tickSize);
//      previousLow = NormalizeD(previousLow, tickSize);
//
//
//      // Check time range and determine entry signals at 8:00 AM to 8:15 AM
//      if (mqlTime.hour == 8 && mqlTime.min <= 15) {
//         Print(mqlTime.hour + ", " + mqlTime.min);
//         string entrySignal = EntrySignal(previousHigh, previousLow);
//         Print("Entry Signal: ", entrySignal);
//         if (entrySignal != "" && !CheckPlacedPositions(MagicNumber)) {
//            Print("OpenTrades!");
//            ulong ticket = OpenTrades(entrySignal, MagicNumber, FixedVolume, UseFillingPolicy, FillingPolicy);
//         }
//      }
//
//      // Close all trades at 9:00 AM
//      if (mqlTime.hour == 9) {
//         CloseAllTrades(MagicNumber, UseFillingPolicy, FillingPolicy);
//      }
//   }
}


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| EA FUNCTIONS                                                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizeD(double price, double tickSize) {
   return round(price/tickSize) * tickSize;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//string EntrySignal(double openPrice, double previousHigh, double previousLow) {
//    double williamsPercentR = iWPR(_Symbol, PERIOD_H1, 14, 0);
//// 매수 신호: 현재 Ask 가격이 이전 시간대의 고가를 상향 돌파하는 경우
//   if (openPrice > previousHigh && williamsPercentR > -90) {
//      Print("Long signal based on current price: ", openPrice);
//      return "LONG"; // 매수 신호 반환
//   }
//
//// 매도 신호: 현재 Bid 가격이 이전 시간대의 저가를 하향 돌파하는 경우
//   if (openPrice < previousLow  && williamsPercentR < -10 ) {
//      Print("Short signal based on current price: ", openPrice);
//      return "SHORT"; // 매도 신호 반환
//   }
//
//   return ""; // 조건에 부합하지 않는 경우, 신호 없음
//}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ExitSignal(double previousHigh, double previousLow, double prePreviousHigh, double prePreviousLow) {
   if (previousHigh < prePreviousHigh) {
      return "EXIT_LONG"; // Signal to close a long position
   } else if (previousLow > prePreviousLow) {
      return "EXIT_SHORT"; // Signal to close a short position
   }
   return ""; // No exit signal
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Low(int pShift) {
   MqlRates bar[];
   ArraySetAsSeries(bar,true);
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,bar);

   return bar[pShift].low;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double High(int pShift) {
   MqlRates bar[];
   ArraySetAsSeries(bar,true);
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,bar);

   return bar[pShift].high;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Close(int pShift) {
   MqlRates bar[];
   ArraySetAsSeries(bar,true);
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,bar);

   return bar[pShift].close;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Open(int pShift) {
   MqlRates bar[];
   ArraySetAsSeries(bar,true);
   CopyRates(_Symbol,PERIOD_CURRENT,0,3,bar);

   return bar[pShift].open;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong OpenTrades(string pEntrySignal,ulong pMagicNumber,double pFixedVol,bool pUseFillingPolicy,ENUM_ORDER_TYPE_FILLING pFillingPolicy) {
//Buy positions open trades at Ask but close them at Bid
//Sell positions open trades at Bid but close them at Ask

   double askPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);

//Price must be normalized either to digits or ticksize
   askPrice = round(askPrice/tickSize) * tickSize;
   bidPrice = round(bidPrice/tickSize) * tickSize;

   string comment = pEntrySignal + " | " + _Symbol + " | " + string(pMagicNumber);

//Request and Result Declaration and Initialization
   MqlTradeRequest request = {};
   MqlTradeResult  result  = {};

   if(pEntrySignal == "LONG") {
      //Request Parameters
      request.action    = TRADE_ACTION_DEAL;
      request.symbol    = _Symbol;
      request.volume    = pFixedVol;
      request.type      = ORDER_TYPE_BUY;
      request.price     = askPrice;
      request.deviation = 30;
      request.magic     = pMagicNumber;
      request.comment   = comment;

      if(pUseFillingPolicy == true) request.type_filling = pFillingPolicy;

      //Request Send
      if(!OrderSend(request,result))
         Print("OrderSend trade placement error: ", GetLastError());     //if request was not send, print error code

      //Trade Information
      Print("Open ",request.symbol," ",pEntrySignal," order #",result.order,": ",result.retcode,", Volume: ",result.volume,", Price: ",DoubleToString(askPrice,_Digits));
   }

   if (pEntrySignal == "SHORT") {
      //Request Parameters
      request.action    = TRADE_ACTION_DEAL;
      request.symbol    = _Symbol;
      request.volume    = pFixedVol;
      request.type      = ORDER_TYPE_SELL;
      request.price     = bidPrice;
      request.deviation = 30;
      request.magic     = pMagicNumber;
      request.comment   = comment;

      if(pUseFillingPolicy == true) request.type_filling = pFillingPolicy;

      //Request Send
      if(!OrderSend(request,result))
         Print("OrderSend trade placement error: ", GetLastError());     //if request was not send, print error code

      //Trade Information
      Print("Open ",request.symbol," ",pEntrySignal," order #",result.order,": ",result.retcode,", Volume: ",result.volume,", Price: ",DoubleToString(bidPrice,_Digits));
   }

   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_DONE_PARTIAL || result.retcode == TRADE_RETCODE_PLACED || result.retcode == TRADE_RETCODE_NO_CHANGES) {
      return result.order;
   } else return 0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseTrades(ulong pMagic,string pExitSignal,bool pUseFillingPolicy,ENUM_ORDER_TYPE_FILLING pFillingPolicy) {
//Request and Result Declaration and Initialization
   MqlTradeRequest request = {};
   MqlTradeResult  result  = {};

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      //Reset of request and result values
      ZeroMemory(request);
      ZeroMemory(result);

      ulong positionTicket = PositionGetTicket(i);
      PositionSelectByTicket(positionTicket);

      ulong posMagic = PositionGetInteger(POSITION_MAGIC);
      ulong posType = PositionGetInteger(POSITION_TYPE);

      if(posMagic == pMagic && pExitSignal == "EXIT_LONG" && posType == ORDER_TYPE_BUY) {
         request.action = TRADE_ACTION_DEAL;
         request.type = ORDER_TYPE_SELL;
         request.symbol = _Symbol;
         request.position = positionTicket;
         request.volume = PositionGetDouble(POSITION_VOLUME);
         request.price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         request.deviation = 30;

         if(pUseFillingPolicy == true) request.type_filling = pFillingPolicy;

         bool sent = OrderSend(request, result);
         if(sent == true) {
            Print("Position #",positionTicket, " closed");
         }
      } else if(posMagic == pMagic && pExitSignal == "EXIT_SHORT" && posType == ORDER_TYPE_SELL) {
         request.action = TRADE_ACTION_DEAL;
         request.type = ORDER_TYPE_BUY;
         request.symbol = _Symbol;
         request.position = positionTicket;
         request.volume = PositionGetDouble(POSITION_VOLUME);
         request.price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         request.deviation = 30;

         if(pUseFillingPolicy == true) request.type_filling = pFillingPolicy;

         bool sent = OrderSend(request, result);
         if(sent == true) {
            Print("Position #",positionTicket, " closed");
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllTrades(ulong magicNumber, bool useFillingPolicy, ENUM_ORDER_TYPE_FILLING fillingPolicy) {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong positionTicket = PositionGetTicket(i);
      if (PositionSelectByTicket(positionTicket)) {
         ulong posMagic = PositionGetInteger(POSITION_MAGIC);
         if (posMagic == magicNumber) {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            string exitSignal = posType == POSITION_TYPE_BUY ? "EXIT_LONG" : "EXIT_SHORT";
            CloseTrades(magicNumber, exitSignal, useFillingPolicy, fillingPolicy);
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckPlacedPositions(ulong pMagic) {
   bool placedPosition = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong positionTicket = PositionGetTicket(i);
      PositionSelectByTicket(positionTicket);

      ulong posMagic = PositionGetInteger(POSITION_MAGIC);

      if(posMagic == pMagic) {
         placedPosition = true;
         break;
      }
   }

   return placedPosition;
}
//+------------------------------------------------------------------+
