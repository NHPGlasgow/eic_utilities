#include <cmath>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <utility>

#include "ROOT/RDataFrame.hxx"
#include <TH1D.h>
#include <TFitResult.h>
#include <TRandom3.h>
#include <TCanvas.h>

#include "TFile.h"
#include "TLorentzVector.h"

#include "TLorentzRotation.h"
#include "TVector2.h"
#include "TVector3.h"

#define MASS_ELECTRON 0.00051
#define MASS_PROTON   0.93827
#define MASS_HELIUM4 3.79493 //wrong at 4th decimal i think

#include "EICStyle.C"

void SimpleAna(const TString infiledir = "/w/work5/home/garyp/eic/ddsim/Topeg/eA-5x41-M3-Ph/82GeV_Steering/", double Ebeam = 5, const double ionbeam=41, const TString ion = "proton")
{
  SetEICStyle();
  //read in files
  auto T = new TChain("events");
  T->Add(infiledir + "*.root");
  TTreeReader trd(T);
  long nev = T->GetEntries();
  if (nev == 0){
    cout << "No events in tree! Exiting without overwriting output files. Check paths!" << endl;
    return(1);
  }

  long ion_pdg;
  double ion_mass;
  
  //pdg for proton / given ion
  if (ion == "proton"){
    ion_pdg = 2212; //proton pdg number
    ion_mass = MASS_PROTON;
  }else if (ion == "helium4"){
    ion_pdg = 1000020040; //helium 4 pdg number
    ion_mass = MASS_HELIUM4;
  }
  
  //MCParticle array details
  TTreeReaderArray<int> mc_genStatus = {trd, "MCParticles.generatorStatus"};
  TTreeReaderArray<float> mc_px = {trd, "MCParticles.momentum.x"};
  TTreeReaderArray<float> mc_py = {trd, "MCParticles.momentum.y"};
  TTreeReaderArray<float> mc_pz = {trd, "MCParticles.momentum.z"};
  TTreeReaderArray<double> mc_mass = {trd, "MCParticles.mass"};
  TTreeReaderArray<int> mc_pdg = {trd, "MCParticles.PDG"};
  
  //output file
  TFile* outfile = new TFile("ana_out.root","RECREATE");

  //histograms
  TH1D *hQ2_MC = new TH1D("hQ2_MC","",100,0,10);
  TH1D *hy_MC = new TH1D("hy_MC","",100,0,1);
  TH1D *hxb_MC = new TH1D("hxb_MC","",100,0,0.2);
  TH1D *ht_MC = new TH1D("ht_MC","",100,0,0.2);
  
  //event loop
  while (trd.Next())
    {
      long ev = trd.GetCurrentEntry();
      if ( ev % 10000 == 0) cout << ev << " / " << nev << endl;
      
      TLorentzVector MCv4_elbeam(0,0,0,0);
      TLorentzVector MCv4_ionbeam(0,0,0,0);
      TLorentzVector MCv4_elscat(0,0,0,0); //scattered electron
      TLorentzVector MCv4_ionscat(0,0,0,0); //scattered ion
      TLorentzVector MCv4_phscat(0,0,0,0); //scattered photon

      TVector3 MCv3_elbeam(0,0,0);
      TVector3 MCv3_prbeam(0,0,0);
      TVector3 MCv3_elscat(0,0,0); //scattered electron
      TVector3 MCv3_ionscat(0,0,0); //scattered ion
      TVector3 MCv3_phscat(0,0,0); //scattered proton
      
      for(int imc=0;imc<mc_px.GetSize();imc++)
	{
	  TVector3 mctrk(mc_px[imc],mc_py[imc],mc_pz[imc]);
	  if(mc_genStatus[imc]==4)// genStatus 4 is beam
	    {
	      //cout << mc_pdg[imc] << endl;
	      if(mc_pdg[imc]==11) MCv4_elbeam.SetVectM(mctrk, MASS_ELECTRON);
	      if(mc_pdg[imc]==ion_pdg) MCv4_ionbeam.SetVectM(mctrk, ion_mass);

	    }//end of if genStatus==4, beam
	  else if (mc_genStatus[imc]==1) //genStatus 1 is for final state particles
	    {
	      if(mc_pdg[imc]==11) MCv4_elscat.SetVectM(mctrk, MASS_ELECTRON);
	      if(mc_pdg[imc]==ion_pdg) MCv4_ionscat.SetVectM(mctrk, ion_mass);
	      if(mc_pdg[imc]==22) MCv4_phscat.SetVectM(mctrk, 0);
	    }//end of if genStatus==1, scatparticle

	  MCv3_elbeam= MCv4_elbeam.Vect();
	  MCv3_prbeam= MCv4_ionbeam.Vect();
	  MCv3_elscat= MCv4_elscat.Vect();
	  MCv3_ionscat= MCv4_ionscat.Vect();
	  MCv3_phscat= MCv4_phscat.Vect();
	}//end of loop over imc
      
      //fill mc vars and histos
      if (true){
      TLorentzVector q_MC=(MCv4_elbeam - MCv4_elscat);
      double Q2_MC = -q_MC.Mag2();
      double t_MC = (MCv4_ionbeam - MCv4_ionscat).Mag2();
      double y_MC = (MCv4_ionbeam*q_MC) / (MCv4_ionbeam*MCv4_elbeam);
      double nu_MC = (MCv4_ionbeam * q_MC)/ion_mass;
      double xb_MC = 2 * Q2_MC / (ion_mass * nu_MC);
      
      //cout << Q2_MC << " " << t_MC << " " << y_MC << " " << xb_MC << " " << nu_MC << endl;
      hQ2_MC->Fill(Q2_MC);
      ht_MC->Fill(-t_MC);
      hxb_MC->Fill(xb_MC);
      hy_MC->Fill(y_MC);
      }

      //now particle reconstruction
      
    }//end of event loop
  
  TCanvas *c1 = new TCanvas("Kinematics","DIS Kinematics");
  c1->Divide(2,2);
  c1->cd(1);
  hQ2_MC->GetXaxis()->SetTitle("Q^{2}_{MC} [GeV^{2}]");
  hQ2_MC->Draw();
  c1->cd(2);
  ht_MC->GetXaxis()->SetTitle("-t_{MC} [GeV^{2}]");
  ht_MC->Draw();
  c1->cd(3);
  hxb_MC->GetXaxis()->SetTitle("x_{B}_{MC}");
  hxb_MC->Draw();
  c1->cd(4);
  hy_MC->GetXaxis()->SetTitle("y_{MC}");
  hy_MC->Draw();
  c1->Print("MC_Kinematics.pdf");
  c1->Write();
  c1->Close();
  
  outfile->Write();
  outfile->Close();
}
  
