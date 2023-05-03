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

void SimpleAna()
{
  //read in files
  auto T = new TChain("events");
  T->Add("/w/work5/home/garyp/eic/Farm/rootfiles/*.root");
  TTreeReader trd(T);
  
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
  TH1D *hMC_Q2 = new TH1D("hMC_Q2","Q^{2}_{MC}",100,0,10);
  
  //pdg for proton / given ion
  long ion_pdg = 10000200400; //helium 4
  //long ion_pdg = 2212 //proton
  
  //event loop
  long nev = T->GetEntries();
  while (trd.Next())
    {
      long ev = trd.GetCurrentEntry();
      if ( ev % 10000 == 0) cout << ev << " / " << nev << endl;
      
      TLorentzVector MCv4_elbeam(0,0,0,0);
      TLorentzVector MCv4_prbeam(0,0,0,0);
      TLorentzVector MCv4_elscat(0,0,0,0); //scattered electron
      TLorentzVector MCv4_prscat(0,0,0,0); //scattered ion
      TLorentzVector MCv4_phscat(0,0,0,0); //scattered photon

      TVector3 MCv3_elbeam(0,0,0);
      TVector3 MCv3_prbeam(0,0,0);
      TVector3 MCv3_elscat(0,0,0); //scattered electron
      TVector3 MCv3_prscat(0,0,0); //scattered ion
      TVector3 MCv3_phscat(0,0,0); //scattered proton
      
      for(int imc=0;imc<mc_px.GetSize();imc++)
	{
	  TVector3 mctrk(mc_px[imc],mc_py[imc],mc_pz[imc]);
	  if(mc_genStatus[imc]==4)// genStatus 4 is beam
	    {
	      if(mc_pdg[imc]==11) MCv4_elbeam.SetVectM(mctrk, MASS_ELECTRON);
	      if(mc_pdg[imc]==ion_pdg) MCv4_prbeam.SetVectM(mctrk, MASS_PROTON);

	    }//end of if genStatus==4, beam
	  else if (mc_genStatus[imc]==1) //genStatus 1 is for final state particles
	    {
	      if(mc_pdg[imc]==11) MCv4_elscat.SetVectM(mctrk, MASS_ELECTRON);
	      if(mc_pdg[imc]==ion_pdg) MCv4_prscat.SetVectM(mctrk, MASS_PROTON);
	      if(mc_pdg[imc]==22) MCv4_phscat.SetVectM(mctrk, 0);
	    }//end of if genStatus==1, scatparticle

	  MCv3_elbeam= MCv4_elbeam.Vect();
	  MCv3_prbeam= MCv4_prbeam.Vect();
	  MCv3_elscat= MCv4_elscat.Vect();
	  MCv3_prscat= MCv4_prscat.Vect();
	  MCv3_phscat= MCv4_phscat.Vect();
	}//end of loop over imc
      
      double Q2_MC=-(MCv4_elbeam - MCv4_elscat).Mag2();  
      
      hMC_Q2->Fill(Q2_MC);
    }//end of event loop

  //TCanvas c1 = new TCanvas("Kinematics","DIS Kinematics");
  //c1->cd();
  //hMC_Q2->Draw();
  //c1->Print();
  //c1->Write();

  outfile->Write();
  outfile->Close();
}
  
