import React from "react";
import styles from "/styles/Navbar.module.css";
import { ConnectWallet, useConnectionStatus } from "@thirdweb-dev/react";

const Navbar = () => {
  const connectionStatus = useConnectionStatus();

  const handleFormSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log("form submitted");
  };

  return (
    <nav className={styles.navbar}>
      <div className={styles.logo}>Logo</div>
      <form onSubmit={handleFormSubmit}>
        <input
          className={styles.searchBar}
          type="text"
          placeholder="Search..."
        />
      </form>
      <ul className={styles.menu}>
        <li className={styles.menuItem}>Projects</li>
        <li className={styles.menuItem}>People</li>
        <li className={styles.menuItem}>How it works</li>
        {connectionStatus === "connected" && (
          <li className={styles.menuItem}>Dashboard</li>
        )}
      </ul>
      <ConnectWallet />
    </nav>
  );
};

export default Navbar;
