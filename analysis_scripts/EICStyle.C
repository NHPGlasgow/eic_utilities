//
// EIC Style, based on a style file from BaBar, v0.1
//

#include <iostream>

#include "EICStyle.h"

#include "TROOT.h"

void SetEICStyle ()
{
  static TStyle* ecceStyle = 0;
  std::cout << "EICStyle: Applying nominal settings." << std::endl ;
  if ( ecceStyle==0 ) ecceStyle = EICStyle();
  gROOT->SetStyle("EIC");
  gROOT->ForceStyle();
}

TStyle* EICStyle() 
{
  TStyle *EICStyle = new TStyle("EIC","EIC style");

  // use plain black on white colors
  Int_t icol=0; // WHITE
  EICStyle->SetFrameBorderMode(icol);
  EICStyle->SetFrameFillColor(icol);
  EICStyle->SetCanvasBorderMode(icol);
  EICStyle->SetCanvasColor(icol);
  EICStyle->SetPadBorderMode(icol);
  EICStyle->SetPadColor(icol);
  EICStyle->SetStatColor(icol);
  //EICStyle->SetFillColor(icol); // don't use: white fill color for *all* objects

  // set the paper & margin sizes
  EICStyle->SetPaperSize(20,26);

  // set margin sizes
  EICStyle->SetPadTopMargin(0.05);
  EICStyle->SetPadRightMargin(0.05);
  EICStyle->SetPadBottomMargin(0.16);
  EICStyle->SetPadLeftMargin(0.16);

  // set title offsets (for axis label)
  EICStyle->SetTitleXOffset(1.4);
  EICStyle->SetTitleYOffset(1.4);

  // use large fonts
  //Int_t font=72; // Helvetica italics
  Int_t font=42; // Helvetica
  Double_t tsize=0.05;
  EICStyle->SetTextFont(font);

  EICStyle->SetTextSize(tsize);
  EICStyle->SetLabelFont(font,"x");
  EICStyle->SetTitleFont(font,"x");
  EICStyle->SetLabelFont(font,"y");
  EICStyle->SetTitleFont(font,"y");
  EICStyle->SetLabelFont(font,"z");
  EICStyle->SetTitleFont(font,"z");
  
  EICStyle->SetLabelSize(tsize,"x");
  EICStyle->SetTitleSize(tsize,"x");
  EICStyle->SetLabelSize(tsize,"y");
  EICStyle->SetTitleSize(tsize,"y");
  EICStyle->SetLabelSize(tsize,"z");
  EICStyle->SetTitleSize(tsize,"z");

  // use bold lines and markers
  EICStyle->SetMarkerStyle(20);
  EICStyle->SetMarkerSize(1.2);
  EICStyle->SetHistLineWidth(2.);
  EICStyle->SetLineStyleString(2,"[12 12]"); // postscript dashes

  // get rid of X error bars 
  //EICStyle->SetErrorX(0.001);
  // get rid of error bar caps
  EICStyle->SetEndErrorSize(0.);

  // do not display any of the standard histogram decorations
  EICStyle->SetOptTitle(0);
  //EICStyle->SetOptStat(1111);
  EICStyle->SetOptStat(0);
  //EICStyle->SetOptFit(1111);
  EICStyle->SetOptFit(0);

  // put tick marks on top and RHS of plots
  EICStyle->SetPadTickX(1);
  EICStyle->SetPadTickY(1);

  // legend modificatin
  EICStyle->SetLegendBorderSize(0);
  EICStyle->SetLegendFillColor(0);
  EICStyle->SetLegendFont(font);


#if ROOT_VERSION_CODE >= ROOT_VERSION(6,00,0)
  std::cout << "EICStyle: ROOT6 mode" << std::endl;
  EICStyle->SetLegendTextSize(tsize);
  EICStyle->SetPalette(kBird);
#else
  std::cout << "EICStyle: ROOT5 mode" << std::endl;
  // color palette - manually define 'kBird' palette only available in ROOT 6
  Int_t alpha = 0;
  Double_t stops[9] = { 0.0000, 0.1250, 0.2500, 0.3750, 0.5000, 0.6250, 0.7500, 0.8750, 1.0000};
  Double_t red[9]   = { 0.2082, 0.0592, 0.0780, 0.0232, 0.1802, 0.5301, 0.8186, 0.9956, 0.9764};
  Double_t green[9] = { 0.1664, 0.3599, 0.5041, 0.6419, 0.7178, 0.7492, 0.7328, 0.7862, 0.9832};
  Double_t blue[9]  = { 0.5293, 0.8684, 0.8385, 0.7914, 0.6425, 0.4662, 0.3499, 0.1968, 0.0539};
  TColor::CreateGradientColorTable(9, stops, red, green, blue, 255, alpha);
#endif

  EICStyle->SetNumberContours(80);

  return EICStyle;

}

