//+------------------------------------------------------------------+
//|                                                    Hansairyo.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

// パラメーター設定
input double InitialLot = 0.01;           // 初期ロット数
input double Multiplier = 2.0;            // ナンピン倍率
input int NampinPips = 200;               // ナンピン幅（pips）
input int TakeProfitPips = 100;           // 利確pips（平均取得単価から）
input int NampinInterval = 30;            // ナンピンインターバル（秒）
input int SpreadMultiplier = 2;           // スプレッド倍率（ナンピン条件用）
input int MagicNumber = 12345;            // マジックナンバー
input string Comment = "Hansairyo";       // オーダーコメント

// グローバル変数
datetime lastNampinTime = 0;              // 最後のナンピン時間
double averagePrice = 0.0;                // 平均取得単価
int totalPositions = 0;                   // 総ポジション数
double totalLots = 0.0;                   // 総ロット数
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("Hansairyo EA初期化中...");
   UpdatePositionInfo();
   Print("EA初期化完了 - ポジション数: ", totalPositions, ", 総ロット: ", totalLots);
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
   UpdatePositionInfo();
   
   // 裁量エントリーされたポジションがある場合のみ処理
   if(totalPositions > 0)
   {
      // ナンピン条件をチェック
      CheckNampinCondition();
      
      // 利確条件をチェック
      CheckTakeProfitCondition();
   }
   
   // 画面表示更新（ポジションの有無に関わらず実行）
   UpdateDisplay();
  }

//+------------------------------------------------------------------+
//| ポジション情報を更新                                           |
//+------------------------------------------------------------------+
void UpdatePositionInfo()
{
   totalPositions = 0;
   totalLots = 0.0;
   double totalPrice = 0.0;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() == MagicNumber || OrderMagicNumber() == 0))
         {
            totalPositions++;
            totalLots += OrderLots();
            totalPrice += OrderOpenPrice() * OrderLots();
         }
      }
   }
   
   if(totalLots > 0)
      averagePrice = totalPrice / totalLots;
   else
      averagePrice = 0.0;
}

//+------------------------------------------------------------------+
//| ナンピン条件をチェック                                         |
//+------------------------------------------------------------------+
void CheckNampinCondition()
{
   if(totalPositions == 0) return;
   
   // インターバルチェック
   if(TimeCurrent() - lastNampinTime < NampinInterval) return;
   
   // 最初のポジションの方向を取得
   int orderType = -1;
   double firstOpenPrice = 0.0;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() == MagicNumber || OrderMagicNumber() == 0))
         {
            orderType = OrderType();
            firstOpenPrice = OrderOpenPrice();
            break;
         }
      }
   }
   
   if(orderType == -1) return;
   
   double currentPrice = (orderType == OP_BUY) ? Bid : Ask;
   double spread = (Ask - Bid) / Point / 10; // スプレッドをpips単位で計算
   double adjustedNampinPips = NampinPips + (spread * SpreadMultiplier); // スプレッドを勘案したナンピン幅
   double pipsDiff = 0.0;
   
   if(orderType == OP_BUY)
   {
      // 買いポジションの場合、価格が下がったらナンピン
      pipsDiff = (averagePrice - currentPrice) / Point / 10;
      if(pipsDiff >= adjustedNampinPips)
      {
         ExecuteNampin(OP_BUY);
      }
   }
   else if(orderType == OP_SELL)
   {
      // 売りポジションの場合、価格が上がったらナンピン
      pipsDiff = (currentPrice - averagePrice) / Point / 10;
      if(pipsDiff >= adjustedNampinPips)
      {
         ExecuteNampin(OP_SELL);
      }
   }
}

//+------------------------------------------------------------------+
//| ナンピンを実行                                                 |
//+------------------------------------------------------------------+
void ExecuteNampin(int orderType)
{
   double nextLotSize = InitialLot;
   
   // 最後のロットサイズを取得して倍率をかける
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() == MagicNumber || OrderMagicNumber() == 0))
         {
            nextLotSize = OrderLots() * Multiplier;
            break;
         }
      }
   }
   
   double price = (orderType == OP_BUY) ? Ask : Bid;
   
   int ticket = OrderSend(Symbol(), orderType, nextLotSize, price, 3, 0, 0, Comment, MagicNumber, 0, clrBlue);
   
   if(ticket > 0)
   {
      lastNampinTime = TimeCurrent();
      Print("ナンピン実行: ロット=", nextLotSize, ", 価格=", price);
   }
   else
   {
      Print("ナンピン失敗: エラー=", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 利確条件をチェック                                             |
//+------------------------------------------------------------------+
void CheckTakeProfitCondition()
{
   if(totalPositions == 0) return;
   
   // 最初のポジションの方向を取得
   int orderType = -1;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() == MagicNumber || OrderMagicNumber() == 0))
         {
            orderType = OrderType();
            break;
         }
      }
   }
   
   if(orderType == -1) return;
   
   double currentPrice = (orderType == OP_BUY) ? Bid : Ask;
   double pipsDiff = 0.0;
   
   if(orderType == OP_BUY)
   {
      pipsDiff = (currentPrice - averagePrice) / Point / 10;
   }
   else if(orderType == OP_SELL)
   {
      pipsDiff = (averagePrice - currentPrice) / Point / 10;
   }
   
   if(pipsDiff >= TakeProfitPips)
   {
      CloseAllPositions(orderType);
   }
}

//+------------------------------------------------------------------+
//| 全ポジションを決済                                             |
//+------------------------------------------------------------------+
void CloseAllPositions(int orderType)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() == MagicNumber || OrderMagicNumber() == 0))
         {
            double closePrice = (orderType == OP_BUY) ? Bid : Ask;
            bool result = OrderClose(OrderTicket(), OrderLots(), closePrice, 3, clrRed);
            
            if(result)
            {
               Print("ポジション決済: チケット=", OrderTicket(), ", 利益=", OrderProfit());
            }
            else
            {
               Print("決済失敗: チケット=", OrderTicket(), ", エラー=", GetLastError());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 画面表示を更新                                                 |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
   string displayText = "";
   displayText += "現在時間: " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\n";
   
   // ポジションがない場合は時間のみ表示
   if(totalPositions == 0)
   {
      displayText += "ポジション: なし";
   }
   else
   {
      displayText += "ポジション数: " + IntegerToString(totalPositions) + "\n";
      displayText += "総ロット: " + DoubleToStr(totalLots, 2) + "\n";
      displayText += "平均価格: " + DoubleToStr(averagePrice, Digits) + "\n";
      
      // 含み損益を計算
      double totalProfit = 0.0;
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && (OrderMagicNumber() == MagicNumber || OrderMagicNumber() == 0))
            {
               totalProfit += OrderProfit();
            }
         }
      }
      
      string profitText = (totalProfit >= 0) ? "含み益: " : "含み損: ";
      displayText += profitText + DoubleToStr(MathAbs(totalProfit), 2);
      
      // スプレッド情報も表示
      double spread = (Ask - Bid) / Point / 10;
      double adjustedNampinPips = NampinPips + (spread * SpreadMultiplier);
      displayText += "\nスプレッド: " + DoubleToStr(spread, 1) + "pips";
      displayText += "\n調整ナンピン幅: " + DoubleToStr(adjustedNampinPips, 1) + "pips";
   }
   
   Comment(displayText);
}
//+------------------------------------------------------------------+
