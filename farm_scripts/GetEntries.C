
void GetEntries(const char* filename, const char* treename = "hepmc") {
    TFile* f = TFile::Open(filename);
    if (!f || f->IsZombie()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return;
    }

    TTree* tree = (TTree*)f->Get(treename);
    if (!tree) {
        std::cerr << "Tree '" << treename << "' not found in file." << std::endl;
        return;
    }

    std::cout << tree->GetEntries() << std::endl;
    f->Close();
}
