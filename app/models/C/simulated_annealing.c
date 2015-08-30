/********************************************
* Víctor José Martín Ramírez                *
* Carlos González Morcillo                  *
* Código bajo licencia GPL 3                *
* => http://www.gnu.org/licenses/gpl.html   *
********************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#define VBN	10000
#define RIGHT 0
#define LEFT 1
#define ALIGNMENT_COST_PER_GROUP 200
#define ALIGNMENT_COMPLETE_POOR 45
#define ALIGNMENT_COMPLETE_GOOD 120
#define ALIGNMENT_COMPLETE_GREAT 150
#define ALIGNMENT_HALFWAY 45
#define ALIGNMENT_MARGINS 20
#define ALIGNMENT_INTEREST 10
#define ALIGNMENT_PERCENTAGE 0.7
#define BALANCE_PERCENTAGE 0.3
#define MAX 100
#define PLAIN 		1.0
#define BACKGROUND  0.0
#define FALSE 	0
#define TRUE 	1
#define VERTICAL 	1
#define HORIZONTAL 	0
#define SMALL_GROWTH 0.20
#define MEDIUM_GROWTH 0.25
#define BIG_GROWTH 0.30

/*Structs*/
struct group{
	int weight;
	int x_pos;
	int y_pos;
	int width;
	int height;
	int normalGroup;
	int x_avg;
	int y_avg;
	int alignment;
};

struct space{
	int x;
	int y;
	int w;
	int h;
};

int l(int t);
void alpha(float *t);
void chooseNeighbour(struct group *candidate, struct space space, int size, float t);
float cost(struct group *candidate, struct space space, struct space interestBox, int size, int designType);
int checkBorders(struct group g, struct space *space, int size);
int checkSpace(struct group *candidate, struct space *space, int orientation, int size);
int getOverlapCost(struct group *candidate, int size);
float getBalanceCost(struct group *candidate, struct space space, int size);
float getAlignmentCost(struct group *candidate, struct space space, struct space interestBox, int size, int designType);
int isOverlapping(struct group one, struct group two);
char * itoa (int i);

int main (int argc, char const *argv[]){
	struct group currentSolution[(argc-11)/8];
	struct group bestSolution[(argc-11)/8];
	struct group candidateSolution[(argc-11)/8];
	struct space whiteSpace,originalWhiteSpace,interestBox;
	int nGroups=(argc-11)/8;
	int i, designType, orientation, keepChecking=TRUE; 
	float tEnd= 10.0, t= 300.0, delta, calc, random;
	char result[MAX];
	
	whiteSpace.x=atoi(argv[1]); whiteSpace.y=atoi(argv[2]);
	whiteSpace.w=atoi(argv[3]); whiteSpace.h=atoi(argv[4]);                                             
	
	interestBox.x=atoi(argv[5]); interestBox.y=atoi(argv[6]);
	interestBox.w=atoi(argv[7]); interestBox.h=atoi(argv[8]);
	
	designType = atoi(argv[9]);
	orientation = atoi(argv[10]);
	
	srand(getpid());
	
	for(i=0;i<nGroups;i++){
		currentSolution[i].weight = 	 atoi(argv[11 + i*8]);
		currentSolution[i].x_pos = 		 atoi(argv[12 + i*8]);
		currentSolution[i].y_pos = 		 atoi(argv[13 + i*8]);
		currentSolution[i].width = 		 atoi(argv[14 + i*8]);
		currentSolution[i].height = 	 atoi(argv[15 + i*8]);
		currentSolution[i].x_avg = 		 atoi(argv[16 + i*8]);
		currentSolution[i].y_avg = 		 atoi(argv[17 + i*8]);
		currentSolution[i].normalGroup = atoi(argv[18 + i*8]);
		currentSolution[i].alignment = 1;
	}

	originalWhiteSpace = whiteSpace;
	
	/*****Simulated Annealing*****/
	memcpy(&bestSolution, &currentSolution, sizeof(currentSolution));
	
	while(t >= tEnd){
		if((int)t%75 == 0 && t!=300.0 && designType==PLAIN && keepChecking==TRUE){
			keepChecking = checkSpace(bestSolution, &whiteSpace, orientation, nGroups);
		}

		for(i = 0; i < l(t); i++){
			memcpy(&candidateSolution, &currentSolution, sizeof(currentSolution));
			chooseNeighbour(candidateSolution, whiteSpace, nGroups, t);
			delta = cost(candidateSolution, whiteSpace, interestBox, nGroups, designType) - cost(currentSolution, whiteSpace, interestBox, nGroups, designType);
			calc = exp(-(delta)/t);
			random = drand48();
			if(random<calc || delta <0)
				memcpy(&currentSolution, &candidateSolution, sizeof(currentSolution));
			if(cost(currentSolution, whiteSpace, interestBox, nGroups, designType) < cost(bestSolution, whiteSpace, interestBox, nGroups, designType))
				memcpy(&bestSolution, &currentSolution, sizeof(currentSolution));
		}
		alpha(&t);
	}
	
	/*Printing the output. This will be get by the main process*/
	
	for(i=0;i<nGroups;i++){
		if(bestSolution[i].normalGroup == 1){
			printf("%i ", bestSolution[i].x_pos);
			printf("%i ", bestSolution[i].y_pos);
			printf("%i ", bestSolution[i].alignment);
		}
	}
	
	/*Cost*/
	printf("%f ", cost(bestSolution, whiteSpace, interestBox, nGroups, designType));
	/*Size modifications*/
	printf("%i ", whiteSpace.w - originalWhiteSpace.w); 	/*Width*/
	printf("%i ", whiteSpace.h - originalWhiteSpace.h); 	/*Height*/
	
	return 0;
}

/*Cheking function*/
int checkSpace(struct group *solution, struct space *space, int orientation, int size){
	int i=0, isOut[size], nOut=0;
	float factor, grow=0;
		
	for(i = 0; i < size; i++){
		if(checkBorders(solution[i], space, size)==TRUE){
			nOut++;
			isOut[i]=TRUE;
		}
		else
			isOut[i]=FALSE;
	}
	
	if(nOut == 1)
		factor = BIG_GROWTH;
	else if(nOut == 2)
		factor = MEDIUM_GROWTH;
	else if(nOut >= 3)
		factor = SMALL_GROWTH;
		
	for(i=0;i<size;i++)
		if(isOut[i]==TRUE)
			grow+= orientation==VERTICAL? solution[i].height*factor : solution[i].width*factor;
	
	grow += (int)grow%20==0?0: 20-(int)grow%20;
	
	if(orientation==VERTICAL)
		space->h+=grow;	
	else
		space->w+=grow;

	if(nOut!=0){
		return TRUE;
	}
	else
		return FALSE;
}

int checkBorders(struct group g, struct space *space, int size){
	int i, isOut=FALSE;
	
	if(g.x_pos < space->x || 
		g.x_pos + g.width > space->x + space->w || 
		g.y_pos < space->y || 
		g.y_pos + g.height > space->y + space->h ){
			isOut=TRUE;
	}
	
	return isOut;
}

/*Cost function. It returns the final cost*/
float cost(struct group *candidate, struct space space, struct space interestBox, int size, int designType){
	int overlapCost;
	float balanceCost, alignmentCost;
	
	/*Overlap Cost*/
	overlapCost = getOverlapCost(candidate, size); 
	
	/*If it's overlapping*/
	if(overlapCost == 1){
		return VBN;
	}
	/*If not...*/
	else{
		/*Balance Cost*/
		balanceCost=getBalanceCost(candidate, space, size);
		/*Alignment Cost*/
		alignmentCost = getAlignmentCost(candidate, space, interestBox, size, designType);
		
		return ((balanceCost*BALANCE_PERCENTAGE)+(alignmentCost*ALIGNMENT_PERCENTAGE));
		
	}
	
}
	
/*Alignment cost*/
float getAlignmentCost(struct group *candidate, struct space space, struct space interestBox, int size, int designType){
	int xAligns[size], yAligns[size], x2Aligns[size], y2Aligns[size];
	int i, j; 
	float totalCost, individualCost, normCost;
	int xCheck, x2Check, yCheck, y2Check, marginLeft, marginRight, marginBottom, marginTop;
	int interestPointLeft, interestPointRight, interestPointUp, interestPointDown; 
	
	for(i=0;i<size;i++){
		xAligns[i]= candidate[i].x_pos;
		yAligns[i]= candidate[i].y_pos;
		x2Aligns[i]= candidate[i].x_pos+candidate[i].width;
		y2Aligns[i]= candidate[i].y_pos+candidate[i].height;
	}
	
	for(i=0;i<size;i++){
		xCheck=0; x2Check=0; yCheck=0; y2Check=0;
		marginLeft=0; marginRight=0; marginBottom=0; marginTop=0;
		interestPointLeft=0; interestPointRight=0; interestPointDown=0; interestPointUp=0;
		
		for(j=0;j<size;j++){
			if(i!=j && candidate[i].normalGroup==1 && candidate[j].normalGroup==1){
				/*X2 Y2 check*/
				if(x2Aligns[i]==x2Aligns[j]){
					x2Check=1;
					candidate[i].alignment= 0;
				}
				else if(y2Aligns[i]==y2Aligns[j])
					y2Check=1;
				
				/*X Y check*/
				if(xAligns[i]==xAligns[j]){
					xCheck=1;
					candidate[i].alignment= 1;
				}
				else if(yAligns[i]==yAligns[j])
					yCheck=1;
				
				/*Margins check */
				if(xAligns[i]==space.x){
					marginLeft=1;
					candidate[i].alignment= 1;
				}
				else if(x2Aligns[i]==space.x+space.w){
					marginRight=1;
					candidate[i].alignment= 0;
				}
				else if(yAligns[i]==space.y){
					marginTop=1;
				}
				else if(y2Aligns[i]==space.y+space.h){
					marginBottom=1;
				}
				/*Interest points check */
				if(xAligns[i]==interestBox.x && designType==BACKGROUND){
					interestPointLeft=1;
					candidate[i].alignment= 1;
				}
				else if(x2Aligns[i]==interestBox.x+interestBox.w  && designType==BACKGROUND){
					interestPointRight=1;
					candidate[i].alignment= 0;
				}
				else if(yAligns[i]==interestBox.y && designType==BACKGROUND)
					interestPointUp=1;
				else if(y2Aligns[i]==interestBox.y+interestBox.h  && designType==BACKGROUND)
					interestPointDown=1;
				
			}//if
		}//for
		
		individualCost = ALIGNMENT_COST_PER_GROUP;
		
		if(((xCheck || x2Check) && (marginLeft || marginRight)) && ((yCheck || y2Check) && (marginTop || marginBottom)))
			individualCost -= ALIGNMENT_COMPLETE_GREAT;
		else if( (marginLeft || marginRight) && (marginTop || marginBottom) )
			individualCost -= ALIGNMENT_COMPLETE_GOOD;
		else if( (xCheck || x2Check) && (yCheck || y2Check) )
			individualCost -= ALIGNMENT_COMPLETE_POOR;
		else if( (xCheck || x2Check || marginLeft || marginRight) || (yCheck || y2Check || marginTop || marginBottom) ) 
			individualCost -= ALIGNMENT_HALFWAY;
			
		if(marginLeft || marginRight)
			individualCost -= ALIGNMENT_MARGINS;
		else if(interestPointDown || interestPointUp || interestPointRight || interestPointLeft)
			individualCost -= ALIGNMENT_INTEREST;
			
		totalCost += individualCost>0? individualCost:0;
	}//for
	
	normCost = totalCost/(ALIGNMENT_COST_PER_GROUP*size);
	
	return normCost;
	
}

/*Balance cost*/
float getBalanceCost(struct group *candidate, struct space space, int size){
	int i, centroidX, centroidY, centerX, centerY;
	float weights=0, xWeights=0, yWeights=0, maxDistance, distance;
	for(i=0;i<size;i++){
		weights+=candidate[i].weight;
		xWeights+= candidate[i].weight+candidate[i].x_avg;
		yWeights+= candidate[i].weight+candidate[i].y_avg;
	}
	
	centroidX = (int) (xWeights/weights);
	centroidY = (int) (yWeights/weights);
	
	centerX = space.w/2;
	centerY = space.h/2;
	
	distance = sqrt(pow(centroidX-centerX, 2) + pow(centroidY-centerY, 2));
	maxDistance = sqrt(pow(space.w, 2) + pow(space.h, 2));

	return distance/maxDistance;
}

/*Overlap cost*/ 
int getOverlapCost(struct group *candidate, int size){
	int i, j;
	int somethingWrong=0;
	
	/*For every two groups, it checks if there is overlapping*/
	for(i = 0; i < size && somethingWrong == 0; i++)
		for(j = 0; j < size && somethingWrong == 0; j++)
			if(i!=j)
				somethingWrong = isOverlapping(candidate[i], candidate[j]);

	return somethingWrong;
}

int isOverlapping(struct group one, struct group two){
	int xCheck, xCheck1, xCheck2, xCheck3, xCheck4;
	int yCheck, yCheck1, yCheck2, yCheck3, yCheck4;
	int final;
	
	/*X checks*/
	xCheck1 = (one.x_pos >= two.x_pos && one.x_pos <= two.x_pos + two.width)?1:0;
	xCheck2 = (one.x_pos+one.width >= two.x_pos && one.x_pos+one.width <= two.x_pos + two.width)?1:0;
	xCheck3 = (two.x_pos >= one.x_pos && two.x_pos<=one.x_pos+one.width)?1:0;
	xCheck4 = (two.x_pos+two.width >= one.x_pos && two.x_pos+two.width<=one.x_pos+one.width)?1:0;
	
	xCheck = xCheck1 + xCheck2 + xCheck3 + xCheck4 > 0?1:0;
	
	/*Y checks*/
	yCheck1 = (one.y_pos >= two.y_pos && one.y_pos <= two.y_pos + two.height)?1:0;
	yCheck2 = (one.y_pos+one.height >= two.y_pos && one.y_pos+one.height <= two.y_pos + two.height)?1:0;
	yCheck3 = (two.y_pos >= one.y_pos && two.y_pos<=one.y_pos+one.height)?1:0;
	yCheck4 = (two.y_pos+two.height >= one.y_pos && two.y_pos+two.height<=one.y_pos+one.height)?1:0;
	
	yCheck = yCheck1 + yCheck2 + yCheck3 + yCheck4 > 0?1:0;
	
	final = xCheck + yCheck > 1?1:0;
	
	return final;
}

/*Neighbour fuction*/
void chooseNeighbour(struct group *candidate, struct space space, int size, float t){
	int i, widthSteps, heightSteps, xJump, yJump;
	int x_pos2, y_pos2, test;
	for(i=0;i<size;i++){
		if(candidate[i].normalGroup == 1){
			widthSteps = (space.w - candidate[i].width)/20;
			heightSteps = (space.h - candidate[i].height)/20;
			
			xJump = widthSteps==0?0:(rand()%widthSteps)*20;
			yJump = heightSteps==0?0:(rand()%heightSteps)*20;
			
			/*Long distances in case Temperature is high; low distances in case it isnt*/
			xJump = (int) (xJump*(t/300.0));
			yJump = (int) (xJump*(t/300.0));
			
			/*Checking the jump is multiple of 20*/
			xJump -= xJump%20!=0?xJump%20:0;
			yJump -= yJump%20!=0?yJump%20:0;
			
			/*Random negative jumps*/
			xJump -= rand()%2==0?0:xJump*2;
			yJump -= rand()%2==0?0:yJump*2;
			
			
			/*Now we move the group with that jumping distance*/
			candidate[i].x_pos += xJump;
			candidate[i].y_pos += yJump;
			
			/*We run some checks on the calculations*/
			x_pos2 = candidate[i].x_pos + candidate[i].width; 
			y_pos2 = candidate[i].y_pos + candidate[i].height;
			
			candidate[i].x_pos = candidate[i].x_pos<space.x?space.x:candidate[i].x_pos;
			candidate[i].y_pos = candidate[i].y_pos<space.y?space.y:candidate[i].y_pos;
			
			candidate[i].x_pos = x_pos2 > space.x + space.w?(space.x+space.w)-candidate[i].width:candidate[i].x_pos;
			candidate[i].y_pos = y_pos2 > space.y + space.h?(space.y+space.h)-candidate[i].height:candidate[i].y_pos;
			
			candidate[i].x_pos -= candidate[i].x_pos%20!=0?candidate[i].x_pos%20:0;
			candidate[i].y_pos -= candidate[i].y_pos%20!=0?candidate[i].y_pos%20:0;
			
			/*We too calculate the average point*/
			candidate[i].x_avg = candidate[i].x_pos + candidate[i].width/2;
			candidate[i].y_avg = candidate[i].y_pos + candidate[i].height/2;
		
		}
	}
}

void alpha(float *t){
	*t=*t-1;
}

int l(int t){
	int k= 100, times;
	times = k - (((k - t)/10)*5);
	return times;
}

char * itoa (int i){
	char str_val [MAX] ;

	snprintf (str_val, sizeof (str_val), "%d", i) ;

	return strdup (str_val) ;
}
