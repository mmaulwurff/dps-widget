version "4.5.0"

class dps_EventHandler : EventHandler
{

  override
  void worldThingDamaged(WorldEvent event)
  {
    if (event.damageSource == players[consolePlayer].mo)
    {
      mDamagePerTic[currentDamageIndex()] += event.damage;
    }
  }

  override
  void worldTick()
  {
    mDamagePerTic[nextDamageIndex()] = 0;

    if (level.time % 35 == 0)
    {
      mHistory[currentHistoryIndex()] = damagePerSecond();
    }
  }

  override
  void renderOverlay(RenderEvent event)
  {
    vector2 start = (50, 50);
    TextureID background = TexMan.checkForTexture("dps_back", TexMan.Type_Any);
    TextureID column = TexMan.checkForTexture("dps_col", TexMan.Type_Any);
    Color c = 0x22DD22;

    int mScale = 1;
    int mScreenWidth  = Screen.getWidth()  / mScale;
    int mScreenHeight = Screen.getHeight() / mScale;

    Screen.drawTexture( background
                      , NO_ANIMATION
                      , start.x
                      , start.y
                      , DTA_FillColor     , c
                      , DTA_AlphaChannel  , true
                      , DTA_Alpha         , 0.5
                      , DTA_VirtualWidth  , mScreenWidth
                      , DTA_VirtualHeight , mScreenHeight
                      , DTA_DestWidth     , GRAPH_WIDTH
                      , DTA_DestHeight    , GRAPH_HEIGHT
                      , DTA_KeepRatio     , true
                      );

    int currentHistoryIndex = nextHistoryIndex();
    int max = maxInHistory();
    for (uint i = 0; i < HISTORY_SECONDS; ++i)
    {
      int index  = (i + currentHistoryIndex) % HISTORY_SECONDS;
      int height = max
        ? GRAPH_HEIGHT * mHistory[index] / max
        : 0;

      Screen.drawTexture( column
                        , NO_ANIMATION
                        , start.x + i
                        , start.y + GRAPH_HEIGHT - height
                        , DTA_FillColor     , c
                        , DTA_AlphaChannel  , true
                        , DTA_Alpha         , 0.5
                        , DTA_VirtualWidth  , mScreenWidth
                        , DTA_VirtualHeight , mScreenHeight
                        , DTA_ClipBottom    , int(start.y + GRAPH_HEIGHT)
                        , DTA_KeepRatio     , true
                        );
    }

    Font bigFont = Font.getFont("BIGFONT");

    String dps = String.format("%d", damagePerSecond());
    int bigTextHeight = bigFont.getHeight();
    int dpsWidth = bigFont.stringWidth(dps);
    Screen.drawText( bigFont
                   , Font.CR_WHITE
                   , start.x + (GRAPH_WIDTH - dpsWidth) / 2
                   , start.y - bigTextHeight
                   , dps
                   , DTA_VirtualWidth  , mScreenWidth
                   , DTA_VirtualHeight , mScreenHeight
                   , DTA_KeepRatio     , true
                   );


    Font smallFont = Font.getFont("SMALLFONT");
    String maxString = String.format("max: %d", max);
    int maxWidth = smallFont.stringWidth(maxString);

    Screen.drawText( smallFont
                   , Font.CR_WHITE
                   , start.x + (GRAPH_WIDTH - maxWidth) / 2
                   , start.y + GRAPH_HEIGHT
                   , maxString
                   , DTA_VirtualWidth  , mScreenWidth
                   , DTA_VirtualHeight , mScreenHeight
                   , DTA_KeepRatio     , true
                   );
  }

// private: ////////////////////////////////////////////////////////////////////////////////////////

  private int currentDamageIndex() const { return ( level.time      % TICRATE); }
  private int nextDamageIndex()    const { return ((level.time + 1) % TICRATE); }

  private
  int damagePerSecond() const
  {
    int result = 0;
    for (uint i = 0; i < TICRATE; ++i)
    {
      result += mDamagePerTic[i];
    }
    return result;
  }

  private int currentHistoryIndex() const { return ((level.time / TICRATE) % HISTORY_SECONDS); }
  private int nextHistoryIndex() const { return (((level.time / TICRATE) + 1) % HISTORY_SECONDS); }

  private
  int maxInHistory() const
  {
    int result = 0;
    for (uint i = 0; i < HISTORY_SECONDS; ++i)
    {
      result = max(mHistory[i], result);
    }
    return result;
  }

  const HISTORY_SECONDS = 60;
  const NO_ANIMATION = 0; // == false
  const GRAPH_HEIGHT = 30;
  const GRAPH_WIDTH  = 60;

  int mDamagePerTic[TICRATE];
  int mHistory[HISTORY_SECONDS];

} // class dps_EventHandler
