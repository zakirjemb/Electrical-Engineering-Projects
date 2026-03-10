import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Database, ref, push, onValue, remove, update } from '@angular/fire/database';

import { MContainerComponent } from '../../m-framework/components/m-container/m-container.component';
import { MCardComponent } from '../../m-framework/components/m-card/m-card.component';
import { MAhaComponent } from '../../m-framework/components/m-aha/m-aha.component';

interface Book {
  title: string;
  author: string;
  genre?: string;
  date?: string;
  read?: boolean;
  key?: string;
}

@Component({
  selector: 'app-obad',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MContainerComponent,
    MCardComponent,
    MAhaComponent
  ],
  templateUrl: './OBAD.component.html',
  styleUrls: ['./OBAD.component.css']
})
export class ObadComponent implements OnInit {
  books: Book[] = [];
  newBook: Book = { title: '', author: '', genre: '', date: '', read: false };
  msg = '';
  lastViewedTitle: string | null = '';

  constructor(private db: Database) {}

  ngOnInit(): void {
    this.loadBooks();
    // Requirement: Local Storage for last viewed book [cite: 28, 29]
    this.lastViewedTitle = localStorage.getItem('lastViewedBook');
  }

  // Requirement: Display total number of books and "Read" count 
  get readCount(): number {
    return this.books.filter(b => b.read).length;
  }

  loadBooks(): void {
    const booksRef = ref(this.db, 'books');
    onValue(booksRef, snapshot => {
      const data = snapshot.val();
      this.books = [];
      if (data) {
        Object.keys(data).forEach(key => {
          this.books.push({ ...(data[key] as Book), key });
        });
      }
    });
  }

  addBook(): void {
    if (!this.newBook.title || !this.newBook.author) {
      this.msg = 'Title and Author are required! [cite: 32]';
      return;
    }

    const booksRef = ref(this.db, 'books');
    push(booksRef, this.newBook);

    // Requirement: Store latest added book in local storage [cite: 16]
    localStorage.setItem('latestBook', JSON.stringify(this.newBook));

    this.msg = 'Book added successfully! [cite: 17]';
    this.newBook = { title: '', author: '', genre: '', date: '', read: false };
    setTimeout(() => (this.msg = ''), 3000);
  }

  deleteBook(book: Book): void {
    if (book.key && confirm('Are you sure you want to delete this book?')) {
      remove(ref(this.db, `books/${book.key}`));
    }
  }

  markRead(book: Book): void {
    if (book.key) {
      update(ref(this.db, `books/${book.key}`), { read: true });
      // Requirement: Update last viewed preference [cite: 28]
      localStorage.setItem('lastViewedBook', book.title);
      this.lastViewedTitle = book.title;
    }
  }
}