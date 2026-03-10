import { Injectable } from '@angular/core';
@Injectable({
  providedIn: 'root'
})
export class MLocaldataService {

  list: any[];
  id: number; 

  constructor() {
    this.list = JSON.parse(localStorage.getItem("list") ?? '[]');
    this.id = parseInt(localStorage.getItem("id") || '1',10); 
   }
 
  add(item:any){
    this.list = [...this.list, item];
    localStorage.setItem("list",JSON.stringify(this.list));
    localStorage.setItem("id", ""+(++this.id));
   
  }
  getList(): any[]{
    this.list = JSON.parse(localStorage.getItem("list") ?? '[]'); 
    return this.list;
  }
  getNextID(): number{
    return this.id;
  }
  remove(ID: number){
    let index = this.list.findIndex( anyitem => anyitem.id == ID);
    if(index != -1) 
    {
      this.list.splice(index,1);
      localStorage.setItem("list",JSON.stringify(this.list)); // How to put anything in local storage
  
    }
  }
  removeAll(){
    this.list = [];
    this.id = 1; 
    localStorage.clear();
  }
}
