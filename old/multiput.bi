#ifndef __MULTIPUT_BI__
#define __MULTIPUT_BI__

' Multiput by D.J.Peters (Joshy)
' MultiPut [destination],[xmidpos],[ymidpos], source,[xScale],[yScale],[Trans]

type FP16 ' fixed point 16:16
  union
  type
    as ushort l
    as  short h
  end type
  as integer v
  end union
end type

#define _ADD_ 0 ' increment a value
#define _CMP_ 1 ' compare values
#define _SET_ 2 ' set a value

#define _XScreen_  0
#define _YScreen_  1
#define _UTexture_ 2
#define _VTexture_ 3

#define _LeftIndex_    0
#define _RightIndex_   1

#define _CurrentIndex_ 0
#define _NextIndex_    1

#define _EdgeXStart_ 0
#define _EdgeUStart_ 1
#define _EdgeVStart_ 2
#define _EdgeXStep_  3
#define _EdgeUStep_  4
#define _EdgeVStep_  5

'#define UseRad 'if not then Rotate are in degrees

Sub MultiPut(Byval pTarget As Any Ptr= 0, _
             Byval xMidPos As Integer= 0, _
             Byval yMidPos As Integer= 0, _
             Byval pSource As Any Ptr   , _
             Byval xScale  As Single = 1, _
             Byval yScale  As Single = 1, _
             Byval Rotate  As Single = 0, _
             Byval Transparent As boolean = false)
  Dim As Integer SourceWidth=any,SourceHeight=any,SourceBytes=any,SourcePitch=any
  Dim as Integer TargetWidth=any,TargetHeight=any,TargetBytes=any,TargetPitch=any
  Dim As Integer i=any,yStart=any,yEnd=any,xStart=any,xEnd=any
  Dim As Integer CNS(1,1)=any 'Counters
  Dim As Integer ACS(1,2)=any '_ADD_ compare and _SET_
  Dim As Single fPoints(3,3)=any,fEdges(2,6)=any,fLength=any,fUSlope=any,fVSlope=any
  Dim As FP16 U=any,V=any,US=any,VS=any
  Dim As boolean MustRotate = iif(Rotate<>0,true,false)

  If (ScreenPtr()=0) Or (pSource=0) Then Exit Sub

  If xScale < 0.001 Then xScale=0.001
  If yScale < 0.001 Then yScale=0.001
 
  If pTarget=0 Then
    ScreenInfo     _
    TargetWidth  , _
    TargetHeight,, _
    TargetBytes  , _
    TargetPitch
    pTarget=ScreenPtr()
  Else
    ImageInfo     _
    pTarget     , _
    TargetWidth , _
    TargetHeight, _
    TargetBytes , _
    TargetPitch , _
    pTarget
  End If
  If (TargetWidth<4) Or (TargetHeight<4) Then Exit Sub

  ImageInfo     _
  pSource     , _
  SourceWidth , _
  SourceHeight, _
  SourceBytes , _
  SourcePitch , _
  pSource

  Select Case as const TargetBytes
  case 1    ' TargetPitch shr=0 : SourcePitch shr=0
  case 2    : TargetPitch shr=1 : SourcePitch shr=1
  case 4    : TargetPitch shr=2 : SourcePitch shr=2
  case else : exit sub
  end select

  fPoints(0,_XScreen_)=-SourceWidth/2 * xScale
  fPoints(1,_XScreen_)= SourceWidth/2 * xScale
  fPoints(2,_XScreen_)= fPoints(1,_XScreen_)
  fPoints(3,_XScreen_)= fPoints(0,_XScreen_)

  fPoints(0,_YScreen_)=-SourceHeight/2 * yScale
  fPoints(1,_YScreen_)= fPoints(0,_YScreen_)
  fPoints(2,_YScreen_)= SourceHeight/2 * yScale
  fPoints(3,_YScreen_)= fPoints(2,_YScreen_)

  fPoints(0,_UTexture_)=0
  fPoints(1,_UTexture_)= SourceWidth
  fPoints(2,_UTexture_)= fPoints(1,_UTexture_)
  fPoints(3,_UTexture_)=0
 
  fPoints(0,_VTexture_)=0
  fPoints(1,_VTexture_)=0
  fPoints(2,_VTexture_)= SourceHeight
  fPoints(3,_VTexture_)= fPoints(2,_VTexture_)

  If MustRotate=true Then
    #ifndef UseRad
    Rotate*=0.017453292 'deg 2 rad
    #endif
    var co = cos(rotate)
    var si = sin(rotate)
    For i=0 To 3
      var x = fPoints(i,_XScreen_)*co - fPoints(i,_YScreen_)*si
      var y = fPoints(i,_XScreen_)*si + fPoints(i,_YScreen_)*co
      fPoints(i,_XScreen_) = x
      fPoints(i,_YScreen_) = y
    Next
  End If
  yStart=30^2:yEnd=-yStart:xStart=yStart:xEnd=yEnd
 
  ' get min max
  For i=0 To 3
    fPoints(i,_XScreen_)=Int(fPoints(i,_XScreen_)+xMidPos)
    fPoints(i,_YScreen_)=Int(fPoints(i,_YScreen_)+yMidPos)
    If fPoints(i,_YScreen_)<yStart Then yStart=fPoints(i,_YScreen_):CNS(_LeftIndex_,_CurrentIndex_)=i
    If fPoints(i,_YScreen_)>yEnd   Then yEnd  =fPoints(i,_YScreen_)
    If fPoints(i,_XScreen_)<xStart Then xStart=fPoints(i,_XScreen_)
    If fPoints(i,_XScreen_)>xEnd   Then xEnd  =fPoints(i,_XScreen_)
  Next

  If yStart = yEnd        Then Exit Sub
  If xStart = xEnd        Then Exit Sub
  If yEnd   < 0           Then Exit Sub
  If xEnd   < 0           Then Exit Sub
  If yStart>=TargetHeight Then Exit Sub
  If xStart>=TargetWidth  Then Exit Sub
 
 
  ACS(_LeftIndex_ ,_ADD_)=-1:ACS(_LeftIndex_ ,_CMP_)=-1:ACS(_LeftIndex_ ,_SET_)=3
  ACS(_RightIndex_,_ADD_)= 1:ACS(_RightIndex_,_CMP_)= 4:ACS(_RightIndex_,_SET_)=0

  ' share the same highest point
  CNS(_RightIndex_,_CurrentIndex_)=CNS(_LeftIndex_,_CurrentIndex_)
 
  ' loop from Top to Bottom
  While yStart<yEnd
    'Scan Left and Right edges together
    For i=_LeftIndex_ To _RightIndex_
      ' bad to read but fast and short ;-)
      If yStart=fPoints(CNS(i,_CurrentIndex_),_YScreen_) Then
        CNS(i,_NextIndex_)=CNS(i,_CurrentIndex_)+ACS(i,_ADD_)
        If CNS(i,_NextIndex_)=ACS(i,_CMP_) Then CNS(i,_NextIndex_)=ACS(i,_SET_)
        While fPoints(CNS(i,_CurrentIndex_),_YScreen_) = fPoints(CNS(i,_NextIndex_),_YScreen_)
          CNS(i,_CurrentIndex_)=CNS(i,_NextIndex_)
          CNS(i,_NextIndex_   )=CNS(i,_CurrentIndex_)+ACS(i,_ADD_)
          If CNS(i,_NextIndex_)=ACS(i,_CMP_) Then CNS(i,_NextIndex_)=ACS(i,_SET_)
        Wend
        fEdges(i,_EdgeXStart_) = fPoints(CNS(i,_CurrentIndex_),_XScreen_)
        fEdges(i,_EdgeUStart_) = fPoints(CNS(i,_CurrentIndex_),_UTexture_)
        fEdges(i,_EdgeVStart_) = fPoints(CNS(i,_CurrentIndex_),_VTexture_)
        fLength  = fPoints(CNS(i,_NextIndex_),_YScreen_) - fPoints(CNS(i,_CurrentIndex_),_YScreen_)
        If fLength <> 0.0 Then
          fLength=1/fLength
          fEdges(i,_EdgeXStep_) = fPoints(CNS(i,_NextIndex_),_XScreen_ )-fEdges(i,_EdgeXStart_):fEdges(i,_EdgeXStep_)*=fLength
          fEdges(i,_EdgeUStep_) = fPoints(CNS(i,_NextIndex_),_UTexture_)-fEdges(i,_EdgeUStart_):fEdges(i,_EdgeUStep_)*=fLength
          fEdges(i,_EdgeVStep_) = fPoints(CNS(i,_NextIndex_),_VTexture_)-fEdges(i,_EdgeVStart_):fEdges(i,_EdgeVStep_)*=fLength
        End If
        CNS(i,_CurrentIndex_)=CNS(i,_NextIndex_)
      End If
    Next

    If (yStart<0)                                                   Then Goto NextScanLine
    xStart=fEdges(_LeftIndex_ ,_EdgeXStart_):If xStart>=TargetWidth Then Goto NextScanLine
    xEnd  =fEdges(_RightIndex_,_EdgeXStart_):If xEnd  < 0           Then Goto NextScanLine
    If (xStart=xEnd)                                                Then Goto NextScanLine
    if xEnd  <xStart                                                Then goto NextScanLine

    fLength=1/(xEnd-xStart)
    fUSlope=fEdges(_RightIndex_,_EdgeUStart_)-fEdges(_LeftIndex_,_EdgeUStart_):fUSlope*=fLength
    fVSlope=fEdges(_RightIndex_,_EdgeVStart_)-fEdges(_LeftIndex_,_EdgeVStart_):fVSlope*=fLength
    If xStart<0 Then
      fLength=-xStart
      U.v=(fEdges(_LeftIndex_,_EdgeUStart_)+fUSlope*fLength)*&HFFFF
      V.v=(fEdges(_LeftIndex_,_EdgeVStart_)+fVSlope*fLength)*&HFFFF
      xStart = 0
    Else
      U.v=fEdges(_LeftIndex_,_EdgeUStart_)*&HFFFF
      V.v=fEdges(_LeftIndex_,_EdgeVStart_)*&HFFFF
    End If
    If u.v<0 Then u.v=0
    If v.v<0 Then v.v=0
    US.v=fUSlope*&HFFFF
    VS.v=fVSlope*&HFFFF

    If xEnd>=TargetWidth Then xEnd=TargetWidth-1

    Select Case as const TargetBytes
    Case 1
      var s=cptr(ubyte ptr,pSource)
      var t=cptr(ubyte ptr,pTarget)+yStart*TargetPitch+xStart
      var e=t+(xEnd-xStart)
      If Transparent=false Then
        While t<e
          *t=*(s+V.h*SourcePitch+U.h)
          V.v+=VS.v : U.v+=US.v : t+=1
        Wend
      Else
        While t<e
          dim as ubyte c=*(s+V.h*SourcePitch+U.h)
          If c Then *t=c
          V.v+=VS.v : U.v+=US.v : t+=1
        Wend
      End If
    Case 2
      var s=cptr(ushort ptr,pSource)
      var t=cptr(ushort ptr,pTarget)+yStart*TargetPitch+xStart
      var e=t+(xEnd-xStart)
      If Transparent=false Then
        While t<e
          *t=*(s+V.h*SourcePitch+U.h)
          V.v+=VS.v : U.v+=US.v : t+=1
        Wend
      Else
        While t<e
          dim as ushort c=*(s+V.h*SourcePitch+U.h)
          If c<>&HF81F Then *t=c
          V.v+=VS.v : U.v+=US.v : t+=1
        Wend
      End If
    Case 4
      var s=cptr(ulong ptr,pSource)
      var t=cptr(ulong ptr,pTarget)+yStart*TargetPitch+xStart
      var e=t+(xEnd-xStart)
      If Transparent=false Then
        While t<e
          *t=*(s+V.h*SourcePitch+U.h)
          V.v+=VS.v : U.v+=US.v : t+=1
        Wend
      Else
        While t<e
          dim as ulong c=*(s+V.h*SourcePitch+U.h)
          If c<>&HFFFF00FF Then *t=c
          V.v+=VS.v : U.v+=US.v : t+=1
        Wend
      End If
    End Select

  NextScanLine:
    yStart+=1 : If yStart=TargetHeight Then exit while
    fEdges(_LeftIndex_ ,_EdgeXStart_)+=fEdges(_LeftIndex_ ,_EdgeXStep_)
    fEdges(_LeftIndex_ ,_EdgeUStart_)+=fEdges(_LeftIndex_ ,_EdgeUStep_)
    fEdges(_LeftIndex_ ,_EdgeVStart_)+=fEdges(_LeftIndex_ ,_EdgeVStep_)
    fEdges(_RightIndex_,_EdgeXStart_)+=fEdges(_RightIndex_,_EdgeXStep_)
    fEdges(_RightIndex_,_EdgeUStart_)+=fEdges(_RightIndex_,_EdgeUStep_)
    fEdges(_RightIndex_,_EdgeVStart_)+=fEdges(_RightIndex_,_EdgeVStep_)
  Wend
End Sub
#endif ' __MULTIPUT_BI__
