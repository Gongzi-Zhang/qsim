#include "qsimGenericDetector.hh"

#include "qsimGenericDetectorHit.hh"
#include "qsimGenericDetectorSum.hh"

#include "G4OpticalPhoton.hh"
#include "G4SDManager.hh"

#include <sstream>

qsimGenericDetector::qsimGenericDetector( G4String name, G4int detnum )
: G4VSensitiveDetector(name),fHitColl(0),fSumColl(0)
{
  fDetNo = detnum;
  assert( fDetNo > 0 );

  //    fTrackSecondaries = false;
  fTrackSecondaries = true;

  std::stringstream genhit;
  genhit << "genhit_" << detnum;
  collectionName.insert(G4String(genhit.str()));

  std::stringstream gensum;
  gensum << "gensum_" << detnum;
  collectionName.insert(G4String(gensum.str()));

  fHCID = -1;
  fSCID = -1;
}

qsimGenericDetector::~qsimGenericDetector(){
}

void qsimGenericDetector::Initialize(G4HCofThisEvent *){

    fHitColl = new qsimGenericDetectorHitCollection( SensitiveDetectorName, collectionName[0] );
    fSumColl = new qsimGenericDetectorSumCollection( SensitiveDetectorName, collectionName[1] );

    fSumMap.clear();

}

///////////////////////////////////////////////////////////////////////

G4bool qsimGenericDetector::ProcessHits( G4Step *step, G4TouchableHistory *){
    G4bool badedep = false;
    G4bool badhit  = false;

    // Ignore optical photons as hits (but still simulate them
    // so they can knock out electrons of the photocathode)
    if (step->GetTrack()->GetDefinition() == G4OpticalPhoton::OpticalPhotonDefinition()) {
      //std::cout << "Return on optical photon" << std::endl;
      return false;
    }

    // Get the step point and track
    G4StepPoint *point = step->GetPreStepPoint();
    G4Track     *track = step->GetTrack();

    // Get touchable volume info
    G4TouchableHistory *hist = (G4TouchableHistory*)(point->GetTouchable());
    //G4int  copyID = hist->GetVolume(1)->GetCopyNo();//return the copy id of the parent volume
    G4int  copyID = hist->GetVolume()->GetCopyNo();//return the copy id of the logical volume

    G4double edep = step->GetTotalEnergyDeposit();

    // We're just going to record primary particles and things
    // that have just entered our boundary
    badhit = true;
    if( track->GetCreatorProcess() == 0 ||
	    (point->GetStepStatus() == fGeomBoundary && fTrackSecondaries)
      ){
	badhit = false;
    }


    //  Make pointer to new hit if it's a valid track
    qsimGenericDetectorHit *thishit;
    if( !badhit ){
	thishit = new qsimGenericDetectorHit(fDetNo, copyID);
	fHitColl->insert( thishit );
    }

    //  Get pointer to our sum  /////////////////////////
    qsimGenericDetectorSum *thissum = NULL;

    if( !fSumMap.count(copyID) ){
	if( edep > 0.0 ){
	    thissum = new qsimGenericDetectorSum(fDetNo, copyID);
	    fSumMap[copyID] = thissum;
	    fSumColl->insert( thissum );
	} else {
	    badedep = true;
	}
    } else {
	thissum = fSumMap[copyID];
    } 
    /////////////////////////////////////////////////////

    // Do the actual data grabbing

    if( !badedep ){
	// This is all we need to do for the sum
	thissum->fEdep += edep;
    }

    if( !badhit ){
	// Hit
	thishit->f3X = point->GetPosition();
	thishit->f3V = track->GetVertexPosition();
	thishit->f3P = track->GetMomentum();

	thishit->fP = track->GetMomentum().mag();
	thishit->fE = track->GetTotalEnergy();
	thishit->fM = track->GetDefinition()->GetPDGMass();

	thishit->fTrID  = track->GetTrackID();
	thishit->fmTrID = track->GetParentID();
	thishit->fPID   = track->GetDefinition()->GetPDGEncoding();

	// FIXME - Enumerate encodings
	thishit->fGen   = (long int) track->GetCreatorProcess();

    }

    return !badedep && !badhit;
}

///////////////////////////////////////////////////////////////////////

void qsimGenericDetector::EndOfEvent(G4HCofThisEvent*HCE) {
    G4SDManager *sdman = G4SDManager::GetSDMpointer();

    if(fHCID<0){ fHCID = sdman->GetCollectionID(collectionName[0]); }
    if(fSCID<0){ fSCID = sdman->GetCollectionID(collectionName[1]); }

    HCE->AddHitsCollection( fHCID, fHitColl );
    HCE->AddHitsCollection( fSCID, fSumColl );

    return;
}


